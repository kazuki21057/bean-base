# Visual Polish & Data Management (Cycle 15) Implementation Plan

## Goal Description
Cycle 15 focuses on refining visual aspects (Image display, Animations) and ensuring data management completeness (Method editing steps).

## User Review Required
None expected, but please confirm the scope covers your needs.

## Proposed Changes

### Image Display Fix
#### [MODIFY] [image_utils.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/utils/image_utils.dart)
- Update `getOptimizedImageUrl` or usage sites to handle local file paths.
- Currently, `Image.network` is used, which fails for local files on PC/Mobile.
- Strategy: Check if path starts with `http` or is a local path.

#### [MODIFY] [master_list_screen.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/screens/master_list_screen.dart)
- Update `_buildPlaceholder` and `Image.network` logic to support local files.
- Use `FileImage` provider for local files.

### Method Editing
#### [MODIFY] [master_add_screen.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/screens/master_add_screen.dart)
- In `MethodAddForm`, load existing steps (`PouringStep`) if `editData` is provided.
- Ensure `MethodStepsEditor` is initialized with existing steps so they can be modified.

#### [MODIFY] [method_detail_screen.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/screens/method_detail_screen.dart)
- Ensure "Edit" button passes specific method data correctly to `MasterAddScreen`.

### UI Polish
#### [MODIFY] [home_screen.dart](file:///c:/src/Antigravity/BeanBase2.0/lib/screens/home_screen.dart)
- Add Empty State handling for "Recent Brews" and "Inventory".
- Add Hero animations for bean images.

## Verification Plan
### Manual Verification
1. **Image Display**:
   - Import a local image for a Bean.
   - Verify it displays in the List and Detail screens.
2. **Method Edit**:
   - Edit an existing method with steps.
   - Verify steps are loaded in the editor.
   - Modify a step and save.
   - Verify changes are reflected in Detail screen.
3. **UI**:
   - Check Hero transitions smooth out navigation.
   - Verify empty states look good when no data exists.
