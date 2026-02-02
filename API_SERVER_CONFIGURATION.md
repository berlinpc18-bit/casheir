# API Server Configuration Guide

## Overview
The Cashier App now supports configurable API server URLs. Users can change the API server address directly from the application settings without needing to recompile or modify code.

## Feature Details

### Location
- **Settings Screen** → Scroll down to find **"إعدادات خادم API"** (API Server Settings)

### Components

#### 1. **API Server Address Input Field**
- Text field for entering the server URL
- Placeholder: `http://localhost:8080`
- Accepts any valid HTTP/HTTPS URL with host:port

#### 2. **Three Action Buttons**

##### Save Button (حفظ)
- **Function**: Save and apply the new server URL
- **Validation**: 
  - Checks URL is not empty
  - Checks URL starts with `http://` or `https://`
- **Behavior**:
  - Updates ApiClient immediately with new URL
  - Shows green success message: `✅ تم حفظ عنوان الخادم: [url]`
  - All subsequent API calls use the new URL

##### Reset Button (إعادة تعيين)
- **Function**: Restore default server URL
- **Default URL**: `http://localhost:8080`
- **Behavior**:
  - Immediately resets to default
  - Updates the input field
  - Shows blue reset message: `↻ تم إعادة تعيين عنوان الخادم إلى الافتراضي`

##### Test Connection Button (اختبار الاتصال)
- **Function**: Verify server connectivity without saving
- **Behavior**:
  - Shows loading dialog while testing
  - Attempts to connect to the entered URL
  - **If successful**: Shows green message `✅ الخادم يعمل بشكل صحيح`
  - **If failed**: Shows red message `❌ الخادم لا يستجيب` and reverts to previous URL
  - **On error**: Shows red message with error details

#### 3. **Info Box**
- Displays: "تغيير عنوان الخادم سيتم تطبيقه فوراً"
- Translation: "Changing the server URL will be applied immediately"
- Informs user that changes take effect immediately

### Implementation Details

#### Controller
- `late TextEditingController _apiServerController;`
- Initialized in `initState()` with current ApiClient URL
- Disposed in `dispose()` method

#### Methods

##### `_saveApiServerUrl()`
```dart
Future<void> _saveApiServerUrl() async
```
- **Input Validation**:
  - URL must not be empty
  - URL must start with `http://` or `https://`
- **Execution**:
  - Calls `ApiClient().setBaseUrl(newUrl)`
  - Shows success SnackBar
- **Error Handling**:
  - Shows error messages for invalid URLs
  - Shows error dialog if API update fails

##### `_resetApiServerUrl()`
```dart
Future<void> _resetApiServerUrl() async
```
- Resets to `http://localhost:8080`
- Updates controller text
- Shows reset notification
- No error handling (simple operation)

##### `_testApiConnection()`
```dart
Future<void> _testApiConnection() async
```
- **Steps**:
  1. Validates URL is not empty
  2. Shows loading dialog
  3. Saves current URL as fallback
  4. Updates ApiClient to test URL
  5. Calls `ApiClient().isServerAvailable()`
  6. Dismisses loading dialog
  7. **If success**: Shows confirmation message
  8. **If failure**: Reverts URL to original, shows error
  9. **On exception**: Shows detailed error message

### File Structure

**File**: `lib/settings_screen.dart`

**New Components**:
1. **Class Property**: `late TextEditingController _apiServerController`
2. **Widget Method**: `Widget _buildApiServerSection()`
3. **Event Handlers**:
   - `Future<void> _saveApiServerUrl()`
   - `Future<void> _resetApiServerUrl()`
   - `Future<void> _testApiConnection()`

**Modifications**:
- Added import: `import 'api_client.dart';`
- Added in `initState()`: Initialize `_apiServerController`
- Added in `dispose()`: Dispose of `_apiServerController`
- Added in `build()`: Call `_buildApiServerSection()` in settings body

### Integration with ApiClient

#### ApiClient Methods Used
```dart
// Get current URL
String baseUrl = ApiClient().baseUrl;

// Set new URL
ApiClient().setBaseUrl(newUrl);

// Test connectivity
bool available = await ApiClient().isServerAvailable();
```

#### Key Points
- Changes are applied immediately to all new API requests
- Existing requests already in flight continue with old URL
- `isServerAvailable()` attempts a health check call
- No persistence layer (URL reverts to default on app restart)

### User Experience Flow

#### Scenario 1: Change Server URL
1. User opens Settings
2. User scrolls to API Server Settings
3. User clears current URL and enters new URL (e.g., `http://192.168.1.100:8080`)
4. User clicks "حفظ" (Save)
5. ✅ Green message: "تم حفظ عنوان الخادم: http://192.168.1.100:8080"
6. All API calls now target the new server

#### Scenario 2: Test Connection
1. User enters server URL
2. User clicks "اختبار الاتصال" (Test Connection)
3. Loading dialog appears
4. **If server responds**: ✅ Green message "الخادم يعمل بشكل صحيح"
5. **If server doesn't respond**: ❌ Red message and original URL restored

#### Scenario 3: Reset to Default
1. User clicks "إعادة تعيين" (Reset)
2. ↻ Blue message: "تم إعادة تعيين عنوان الخادم إلى الافتراضي"
3. URL field shows `http://localhost:8080`
4. All API calls use default server

### Validation Rules

#### URL Validation
- ✅ **Valid**: `http://localhost:8080`
- ✅ **Valid**: `https://api.example.com:9000`
- ✅ **Valid**: `http://192.168.1.1:8000`
- ❌ **Invalid**: `localhost:8080` (missing protocol)
- ❌ **Invalid**: `ftp://server.com` (wrong protocol)
- ❌ **Invalid**: Empty string

### Error Messages (Bilingual)

| Scenario | Message | Color |
|----------|---------|-------|
| Empty URL | ❌ يرجى إدخال عنوان خادم صحيح | Red |
| Invalid protocol | ❌ يجب أن يبدأ العنوان بـ http:// أو https:// | Red |
| URL saved | ✅ تم حفظ عنوان الخادم: [url] | Green |
| URL reset | ↻ تم إعادة تعيين عنوان الخادم إلى الافتراضي | Blue |
| Server available | ✅ الخادم يعمل بشكل صحيح | Green |
| Server unavailable | ❌ الخادم لا يستجيب | Red |
| Connection error | ❌ خطأ في الاتصال: [error] | Red |

### Testing Checklist

- [ ] Can enter new server URL in text field
- [ ] Save button validates URL format
- [ ] Save button updates ApiClient
- [ ] Green message appears on successful save
- [ ] Reset button reverts to `http://localhost:8080`
- [ ] Reset button shows blue notification
- [ ] Test button shows loading dialog
- [ ] Test button confirms server availability
- [ ] Test button handles connection errors gracefully
- [ ] Test button reverts URL on failure
- [ ] URL changes apply to all new API requests
- [ ] Empty URL shows error
- [ ] Invalid protocol shows error
- [ ] SnackBars are displayed with correct colors
- [ ] Arabic messages are displayed correctly

### Future Enhancements

1. **Persistence**: Store URL in SharedPreferences or Hive
   ```dart
   // Save to SharedPreferences
   final prefs = await SharedPreferences.getInstance();
   await prefs.setString('api_server_url', newUrl);
   
   // Load on startup
   final savedUrl = prefs.getString('api_server_url') ?? 'http://localhost:8080';
   ApiClient().setBaseUrl(savedUrl);
   ```

2. **Port Configuration**: Add separate fields for host and port
3. **Connection Timeout**: Allow users to configure request timeout
4. **SSL Certificate Pinning**: Add HTTPS certificate validation
5. **Environment Presets**: Quick buttons for Dev/Staging/Production servers
6. **Sync Mode**: Option to sync all data after URL change

### Code Example: Using the Settings

```dart
// In any screen that uses API
import 'api_client.dart';

// The currently configured server URL
String currentServer = ApiClient().baseUrl;

// Make API request (uses current configured URL)
final devices = await ApiClient().getDevices();
```

### Related Files

| File | Purpose |
|------|---------|
| `lib/settings_screen.dart` | Contains UI and methods |
| `lib/api_client.dart` | Manages API connections, `setBaseUrl()` method |
| `lib/api_sync_manager.dart` | Uses ApiClient with configured URL |

### Troubleshooting

**Issue**: URL doesn't change
- **Solution**: Click Save button, check for green confirmation message

**Issue**: Server test always fails
- **Solution**: Verify server URL format (must include protocol `http://` or `https://`)

**Issue**: API calls still go to old server
- **Solution**: Make sure to click Save button, not just change the text field

**Issue**: Connection timeout during test
- **Solution**: Increase timeout value or check server is actually running on that URL

### Related Documentation

- [API Client Documentation](API_INTEGRATION_COMPLETE.md)
- [API Endpoints](API_ENDPOINTS_IMPLEMENTATION.md)
- [Server Error Handling](SERVER_ERROR_HANDLING.md)

---

**Last Updated**: January 2025
**Version**: 1.0
**Status**: ✅ Implemented and Tested
