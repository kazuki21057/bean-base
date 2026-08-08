#!/usr/bin/env bash
#
# Android実機代わりのAVD「beanbase_test」を起動/停止するスクリプト(Ubuntu/Bash版)。
# 対となる Windows/PowerShell 版は tools/emulator.ps1。
#
# T5-A6(改修マスタープラン)で整備したAndroidエミュレータ環境を、
# 非対話・自動化しやすい形で起動/停止するためのラッパー。
# ヘッドレスではなく通常のGUIウィンドウでエミュレータを起動する。
#
# 使い方:
#   tools/emulator.sh start [avd_name] [timeout_sec]
#   tools/emulator.sh stop  [avd_name] [timeout_sec]
#   tools/emulator.sh status [avd_name]
#
# 既定値: avd_name=beanbase_test, timeout_sec=180

set -euo pipefail

COMMAND="${1:-}"
AVD_NAME="${2:-beanbase_test}"
TIMEOUT_SEC="${3:-180}"

resolve_sdk_root() {
    if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
        echo "$ANDROID_SDK_ROOT"
    elif [ -n "${ANDROID_HOME:-}" ]; then
        echo "$ANDROID_HOME"
    else
        echo "$HOME/Android/Sdk"
    fi
}

SDK_ROOT="$(resolve_sdk_root)"
EMULATOR_BIN="$SDK_ROOT/emulator/emulator"
ADB_BIN="$SDK_ROOT/platform-tools/adb"

assert_tooling() {
    if [ ! -x "$EMULATOR_BIN" ]; then
        echo "エラー: エミュレータ本体が見つかりません: $EMULATOR_BIN" >&2
        echo "(Android SDKのセットアップ(T5-A6手順)を先に実施してください。ANDROID_SDK_ROOT=$SDK_ROOT)" >&2
        exit 1
    fi
    if [ ! -x "$ADB_BIN" ]; then
        echo "エラー: adbが見つかりません: $ADB_BIN" >&2
        echo "(platform-toolsのインストールを確認してください。ANDROID_SDK_ROOT=$SDK_ROOT)" >&2
        exit 1
    fi
}

get_running_avd_serial() {
    local name="$1"
    local serial
    for serial in $("$ADB_BIN" devices 2>/dev/null | awk '/^emulator-[0-9]+\s+device$/ {print $1}'); do
        local avd_on_device
        avd_on_device="$("$ADB_BIN" -s "$serial" emu avd name 2>/dev/null | head -n1 | tr -d '\r')"
        if [ "$avd_on_device" = "$name" ]; then
            echo "$serial"
            return 0
        fi
    done
    return 1
}

start_avd() {
    assert_tooling

    local existing
    if existing="$(get_running_avd_serial "$AVD_NAME")"; then
        echo "AVD '$AVD_NAME' は既に起動しています(シリアル: $existing)。"
        return 0
    fi

    if ! "$EMULATOR_BIN" -list-avds | grep -qx "$AVD_NAME"; then
        echo "エラー: AVD '$AVD_NAME' が見つかりません。作成済みAVD一覧:" >&2
        "$EMULATOR_BIN" -list-avds >&2
        exit 1
    fi

    echo "AVD '$AVD_NAME' を起動しています(通常ウィンドウ表示)..."
    nohup "$EMULATOR_BIN" -avd "$AVD_NAME" -netdelay none -netspeed full \
        > /tmp/beanbase_emulator_"$AVD_NAME".log 2>&1 &
    local emu_pid=$!
    echo "エミュレータプロセスを起動しました(PID: $emu_pid)。ブート完了を待機します..."

    local deadline=$(( $(date +%s) + TIMEOUT_SEC ))
    local serial=""
    while [ "$(date +%s)" -lt "$deadline" ]; do
        if serial="$(get_running_avd_serial "$AVD_NAME")"; then
            break
        fi
        sleep 3
    done

    if [ -z "$serial" ]; then
        echo "エラー: タイムアウト(${TIMEOUT_SEC}秒)までにAVD '$AVD_NAME' がadbデバイス一覧に現れませんでした。" >&2
        exit 1
    fi

    "$ADB_BIN" -s "$serial" wait-for-device

    local booted="false"
    while [ "$(date +%s)" -lt "$deadline" ]; do
        local boot_completed
        boot_completed="$("$ADB_BIN" -s "$serial" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"
        if [ "$boot_completed" = "1" ]; then
            booted="true"
            break
        fi
        sleep 3
    done

    if [ "$booted" != "true" ]; then
        echo "エラー: タイムアウト(${TIMEOUT_SEC}秒)までにAVD '$AVD_NAME' のブートが完了しませんでした(シリアル: $serial)。" >&2
        exit 1
    fi

    echo "AVD '$AVD_NAME' の起動が完了しました(シリアル: $serial)。'flutter devices' で確認できます。"
}

stop_avd() {
    assert_tooling

    local serial
    if ! serial="$(get_running_avd_serial "$AVD_NAME")"; then
        echo "AVD '$AVD_NAME' は起動していません。"
        return 0
    fi

    echo "AVD '$AVD_NAME' を終了しています(シリアル: $serial)..."
    "$ADB_BIN" -s "$serial" emu kill || true

    local deadline=$(( $(date +%s) + TIMEOUT_SEC ))
    while [ "$(date +%s)" -lt "$deadline" ]; do
        if ! get_running_avd_serial "$AVD_NAME" > /dev/null; then
            echo "AVD '$AVD_NAME' を終了しました。"
            return 0
        fi
        sleep 2
    done

    echo "警告: タイムアウト(${TIMEOUT_SEC}秒)までにAVD '$AVD_NAME' の終了を確認できませんでした。プロセスの確認を推奨します。" >&2
}

show_status() {
    assert_tooling
    local serial
    if serial="$(get_running_avd_serial "$AVD_NAME")"; then
        echo "AVD '$AVD_NAME' は起動中です(シリアル: $serial)。"
    else
        echo "AVD '$AVD_NAME' は停止しています。"
    fi
}

case "$COMMAND" in
    start)
        start_avd
        ;;
    stop)
        stop_avd
        ;;
    status)
        show_status
        ;;
    *)
        echo "使い方: tools/emulator.sh start|stop|status [avd_name] [timeout_sec]"
        echo "  既定値: avd_name=beanbase_test, timeout_sec=180"
        exit 1
        ;;
esac
