import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { en, vi }

class LocaleNotifier extends Notifier<AppLocale> {
  static const _localeKey = 'app_locale';

  @override
  AppLocale build() {
    _loadLocale();
    return AppLocale.en;
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    if (savedLocale != null) {
      state = savedLocale == 'vi' ? AppLocale.vi : AppLocale.en;
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale == AppLocale.vi ? 'vi' : 'en');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(() {
  return LocaleNotifier();
});

class AppTranslations {
  static const Map<String, Map<AppLocale, String>> _keys = {
    // Navigation / Shell Route
    'nav_calendar': {AppLocale.en: 'Calendar', AppLocale.vi: 'Lịch'},
    'nav_habits': {AppLocale.en: 'Habits', AppLocale.vi: 'Thói quen'},
    'nav_squad': {AppLocale.en: 'Squad', AppLocale.vi: 'Nhóm'},
    'nav_settings': {AppLocale.en: 'Settings', AppLocale.vi: 'Cài đặt'},

    // Login Screen
    'login_title': {AppLocale.en: 'Login', AppLocale.vi: 'Đăng nhập'},
    'welcome_back': {AppLocale.en: 'Welcome Back', AppLocale.vi: 'Chào mừng trở lại'},
    'email_placeholder': {AppLocale.en: 'Email', AppLocale.vi: 'Email'},
    'password_placeholder': {AppLocale.en: 'Password', AppLocale.vi: 'Mật khẩu'},
    'login_button': {AppLocale.en: 'Login', AppLocale.vi: 'Đăng nhập'},
    'create_account_link': {AppLocale.en: 'Create an account', AppLocale.vi: 'Tạo tài khoản mới'},
    'go_to_register': {AppLocale.en: 'Need an account? Register', AppLocale.vi: 'Chưa có tài khoản? Đăng ký'},
    'login_failed_title': {AppLocale.en: 'Login Failed', AppLocale.vi: 'Đăng nhập thất bại'},
    'login_failed_desc': {AppLocale.en: 'Invalid email or password. Please try again.', AppLocale.vi: 'Email hoặc mật khẩu không chính xác. Vui lòng thử lại.'},
    
    // Register Screen
    'register_title': {AppLocale.en: 'Create Account', AppLocale.vi: 'Đăng ký tài khoản'},
    'confirm_password_placeholder': {AppLocale.en: 'Confirm Password', AppLocale.vi: 'Xác nhận mật khẩu'},
    'register_button': {AppLocale.en: 'Register', AppLocale.vi: 'Đăng ký'},
    'back_to_login': {AppLocale.en: 'Back to Login', AppLocale.vi: 'Quay lại Đăng nhập'},
    'pwd_mismatch_title': {AppLocale.en: 'Passwords do not match', AppLocale.vi: 'Mật khẩu không khớp'},
    'pwd_mismatch_desc': {AppLocale.en: 'Please make sure both passwords are the same.', AppLocale.vi: 'Vui lòng đảm bảo hai mật khẩu trùng khớp.'},
    'account_created_title': {AppLocale.en: 'Account Created', AppLocale.vi: 'Đăng ký thành công'},
    'account_created_desc': {AppLocale.en: 'Your account has been created. You can now log in.', AppLocale.vi: 'Tài khoản của bạn đã được tạo. Bạn có thể đăng nhập ngay.'},
    'reg_failed_title': {AppLocale.en: 'Registration Failed', AppLocale.vi: 'Đăng ký thất bại'},
    'reg_failed_default': {AppLocale.en: 'Could not create account. Please try again.', AppLocale.vi: 'Không thể tạo tài khoản. Vui lòng thử lại.'},
    'pwd_reqs_title': {AppLocale.en: 'Password Requirements:', AppLocale.vi: 'Yêu cầu đối với mật khẩu:'},
    'req_len': {AppLocale.en: 'At least 6 characters', AppLocale.vi: 'Ít nhất 6 ký tự'},
    'req_lower': {AppLocale.en: 'At least one lowercase letter (a-z)', AppLocale.vi: 'Ít nhất một chữ thường (a-z)'},
    'req_upper': {AppLocale.en: 'At least one uppercase letter (A-Z)', AppLocale.vi: 'Ít nhất một chữ hoa (A-Z)'},
    'req_digit': {AppLocale.en: 'At least one digit (0-9)', AppLocale.vi: 'Ít nhất một chữ số (0-9)'},
    'req_special': {AppLocale.en: 'At least one special character (!, @, #, ...)', AppLocale.vi: 'Ít nhất một ký tự đặc biệt (!, @, #, ...)'},

    // Settings Screen
    'settings_title': {AppLocale.en: 'Settings', AppLocale.vi: 'Cài đặt'},
    'cosmetics_title': {AppLocale.en: 'Cosmetics & Rewards', AppLocale.vi: 'Trang phục & Phần thưởng'},
    'cosmetics_subtitle': {AppLocale.en: 'View your level and unlock emojis/colors', AppLocale.vi: 'Xem cấp độ và mở khóa biểu tượng/màu sắc'},
    'language_title': {AppLocale.en: 'Language', AppLocale.vi: 'Ngôn ngữ'},
    'select_language_title': {AppLocale.en: 'Select Language', AppLocale.vi: 'Chọn ngôn ngữ'},
    'select_language_desc': {AppLocale.en: 'Choose your preferred language:', AppLocale.vi: 'Chọn ngôn ngữ bạn muốn sử dụng:'},
    'logout_title': {AppLocale.en: 'Log Out', AppLocale.vi: 'Đăng xuất'},
    'logout_subtitle': {AppLocale.en: 'Sign out of your account', AppLocale.vi: 'Đăng xuất khỏi tài khoản của bạn'},
    'logout_confirm_title': {AppLocale.en: 'Log Out', AppLocale.vi: 'Đăng xuất'},
    'logout_confirm_desc': {AppLocale.en: 'Are you sure you want to log out?', AppLocale.vi: 'Bạn có chắc chắn muốn đăng xuất không?'},
    'cancel': {AppLocale.en: 'Cancel', AppLocale.vi: 'Hủy'},

    // Calendar
    'calendar_settings_title': {AppLocale.en: 'Calendar Settings', AppLocale.vi: 'Cài đặt lịch'},
    'cal_view_day': {AppLocale.en: 'Day', AppLocale.vi: 'Ngày'},
    'cal_view_3day': {AppLocale.en: '3-Day', AppLocale.vi: '3 Ngày'},
    'cal_view_month': {AppLocale.en: 'Month', AppLocale.vi: 'Tháng'},
    'filter_all': {AppLocale.en: 'All', AppLocale.vi: 'Tất cả'},
    'filter_personal': {AppLocale.en: 'Personal', AppLocale.vi: 'Cá nhân'},
    'filter_squads': {AppLocale.en: 'Squads', AppLocale.vi: 'Nhóm'},
    'events_count': {AppLocale.en: 'events', AppLocale.vi: 'sự kiện'},
    'all_categories': {AppLocale.en: 'All Categories', AppLocale.vi: 'Tất cả danh mục'},
    'category_health': {AppLocale.en: 'Health', AppLocale.vi: 'Sức khỏe'},
    'category_work': {AppLocale.en: 'Work', AppLocale.vi: 'Công việc'},
    'category_learning': {AppLocale.en: 'Learning', AppLocale.vi: 'Học tập'},
    'category_wellness': {AppLocale.en: 'Wellness', AppLocale.vi: 'Sức khỏe tinh thần'},
    'unknown_habit': {AppLocale.en: 'Unknown', AppLocale.vi: 'Không xác định'},
    'uncategorized': {AppLocale.en: 'Uncategorized', AppLocale.vi: 'Chưa phân loại'},

    // Create Event Sheet
    'schedule_event': {AppLocale.en: 'Schedule Event', AppLocale.vi: 'Lên lịch sự kiện'},
    'title': {AppLocale.en: 'Title', AppLocale.vi: 'Tiêu đề'},
    'event_title_placeholder': {AppLocale.en: 'Event title', AppLocale.vi: 'Tiêu đề sự kiện'},
    'category': {AppLocale.en: 'Category', AppLocale.vi: 'Danh mục'},
    'select_category': {AppLocale.en: 'Select category', AppLocale.vi: 'Chọn danh mục'},
    'date': {AppLocale.en: 'Date', AppLocale.vi: 'Ngày'},
    'time': {AppLocale.en: 'Time', AppLocale.vi: 'Thời gian'},
    'target_duration': {AppLocale.en: 'Target Duration (mins)', AppLocale.vi: 'Thời lượng mục tiêu (phút)'},
    'duration_placeholder': {AppLocale.en: 'e.g. 45', AppLocale.vi: 'Ví dụ: 45'},
    'create_event_btn': {AppLocale.en: 'Create Event', AppLocale.vi: 'Tạo sự kiện'},
    'title_required_toast': {AppLocale.en: 'Title is required', AppLocale.vi: 'Tiêu đề không được để trống'},
    'event_created_toast': {AppLocale.en: 'Event Created', AppLocale.vi: 'Đã tạo sự kiện'},
    'scheduled_event_toast': {AppLocale.en: 'Scheduled', AppLocale.vi: 'Đã lên lịch'},

    // Calendar Settings
    'visible_hours': {AppLocale.en: 'Visible Hours', AppLocale.vi: 'Giờ hiển thị'},
    'visible_hours_desc': {AppLocale.en: 'Select the time range visible in the calendar grid.', AppLocale.vi: 'Chọn khoảng thời gian hiển thị trên lịch.'},
    'start_hour': {AppLocale.en: 'Start Hour', AppLocale.vi: 'Giờ bắt đầu'},
    'end_hour': {AppLocale.en: 'End Hour', AppLocale.vi: 'Giờ kết thúc'},
    'done': {AppLocale.en: 'Done', AppLocale.vi: 'Xong'},

    // Event Details Dialog
    'event_details': {AppLocale.en: 'Event Details', AppLocale.vi: 'Chi tiết sự kiện'},
    'status': {AppLocale.en: 'Status', AppLocale.vi: 'Trạng thái'},
    'completed': {AppLocale.en: 'Completed', AppLocale.vi: 'Hoàn thành'},
    'pending': {AppLocale.en: 'Pending', AppLocale.vi: 'Chờ xử lý'},
    'mark_pending': {AppLocale.en: 'Mark as Pending', AppLocale.vi: 'Đánh dấu chưa hoàn thành'},
    'start_focus': {AppLocale.en: 'Start Focus Session', AppLocale.vi: 'Bắt đầu tập trung'},
    'close': {AppLocale.en: 'Close', AppLocale.vi: 'Đóng'},

    // Unscheduled Habits Panel
    'unscheduled_habits': {AppLocale.en: 'Unscheduled Habits', AppLocale.vi: 'Thói quen chưa lên lịch'},
    'unscheduled_habits_desc': {AppLocale.en: 'Unscheduled Habits (Drag to Calendar)', AppLocale.vi: 'Thói quen chưa lên lịch (Kéo vào Lịch)'},
    'no_unscheduled_habits': {AppLocale.en: 'No habits yet. Go to Habits tab to create one.', AppLocale.vi: 'Chưa có thói quen nào. Đi tới tab Thói quen để tạo mới.'},

    // Habits Screen & Heatmap
    'activity_heatmap': {AppLocale.en: 'Activity (Last 90 Days)', AppLocale.vi: 'Hoạt động (90 ngày qua)'},
    'heatmap_less': {AppLocale.en: 'Less', AppLocale.vi: 'Ít'},
    'heatmap_more': {AppLocale.en: 'More', AppLocale.vi: 'Nhiều'},
    'days_week': {AppLocale.en: 'days/week', AppLocale.vi: 'ngày/tuần'},
    'no_habits_yet': {AppLocale.en: 'No habits yet. Tap + to add.', AppLocale.vi: 'Chưa có thói quen nào. Nhấn + để thêm.'},
    'add_habit': {AppLocale.en: 'Add Habit', AppLocale.vi: 'Thêm thói quen'},
    'add_habit_desc': {AppLocale.en: 'Enter the details for your new habit.', AppLocale.vi: 'Nhập thông tin chi tiết cho thói quen mới.'},
    'edit_habit': {AppLocale.en: 'Edit Habit', AppLocale.vi: 'Chỉnh sửa thói quen'},
    'edit_habit_desc': {AppLocale.en: 'Modify the details of your habit.', AppLocale.vi: 'Thay đổi thông tin chi tiết của thói quen.'},
    'delete_habit': {AppLocale.en: 'Delete Habit', AppLocale.vi: 'Xóa thói quen'},
    'delete_habit_confirm': {AppLocale.en: 'Are you sure you want to delete this habit?', AppLocale.vi: 'Bạn có chắc chắn muốn xóa thói quen này không?'},
    'habit_name_placeholder': {AppLocale.en: 'Habit Name', AppLocale.vi: 'Tên thói quen'},
    'add_btn': {AppLocale.en: 'Add', AppLocale.vi: 'Thêm'},
    'save_btn': {AppLocale.en: 'Save', AppLocale.vi: 'Lưu'},
    'delete_btn': {AppLocale.en: 'Delete', AppLocale.vi: 'Xóa'},
    'target_days': {AppLocale.en: 'Target Days', AppLocale.vi: 'Ngày thực hiện'},
    'habit_name_empty': {AppLocale.en: 'Habit name cannot be empty', AppLocale.vi: 'Tên thói quen không được để trống'},
    'habit_updated_toast': {AppLocale.en: 'Habit updated successfully', AppLocale.vi: 'Đã cập nhật thói quen thành công'},
    'habit_deleted_toast': {AppLocale.en: 'Habit deleted successfully', AppLocale.vi: 'Đã xóa thói quen thành công'},
    'error_heatmap': {AppLocale.en: 'Error loading heatmap:', AppLocale.vi: 'Lỗi khi tải heatmap:'},

    // Focus Session (Pomodoro)
    'pomodoro_timer': {AppLocale.en: 'Pomodoro Timer', AppLocale.vi: 'Đồng hồ Pomodoro'},
    'status_label': {AppLocale.en: 'Status', AppLocale.vi: 'Trạng thái'},
    'status_ready': {AppLocale.en: 'READY', AppLocale.vi: 'SẴN SÀNG'},
    'status_running': {AppLocale.en: 'RUNNING', AppLocale.vi: 'ĐANG CHẠY'},
    'status_paused': {AppLocale.en: 'PAUSED', AppLocale.vi: 'ĐANG TẠM DỪNG'},
    'status_overtime': {AppLocale.en: 'OVERTIME', AppLocale.vi: 'QUÁ GIỜ'},
    'status_finished': {AppLocale.en: 'FINISHED', AppLocale.vi: 'ĐÃ HOÀN THÀNH'},
    'start': {AppLocale.en: 'Start', AppLocale.vi: 'Bắt đầu'},
    'pause': {AppLocale.en: 'Pause', AppLocale.vi: 'Tạm dừng'},
    'resume': {AppLocale.en: 'Resume', AppLocale.vi: 'Tiếp tục'},
    'reset': {AppLocale.en: 'Reset', AppLocale.vi: 'Đặt lại'},
    'focus_session_title': {AppLocale.en: 'Focus Session', AppLocale.vi: 'Phiên tập trung'},
    'target_reached': {AppLocale.en: 'Target Reached!', AppLocale.vi: 'Đã đạt mục tiêu!'},
    'complete_session': {AppLocale.en: 'Complete Session', AppLocale.vi: 'Hoàn thành phiên'},
    'expand_time': {AppLocale.en: 'Expand Time', AppLocale.vi: 'Thêm thời gian'},
    'finish_session': {AppLocale.en: 'Finish Session', AppLocale.vi: 'Kết thúc phiên'},
    'finish_now': {AppLocale.en: 'Finish Now', AppLocale.vi: 'Kết thúc ngay'},

    // Post Focus Session Dialog
    'session_complete': {AppLocale.en: 'Session Complete!', AppLocale.vi: 'Hoàn thành phiên!'},
    'focused_minutes': {AppLocale.en: 'You focused for', AppLocale.vi: 'Bạn đã tập trung trong'},
    'minutes_label': {AppLocale.en: 'minutes.', AppLocale.vi: 'phút.'},
    'target': {AppLocale.en: 'Target', AppLocale.vi: 'Mục tiêu'},
    'actual': {AppLocale.en: 'Actual', AppLocale.vi: 'Thực tế'},
    'overtime_question': {AppLocale.en: 'You went overtime! Do you want to update the calendar to reflect your actual time?', AppLocale.vi: 'Bạn đã tập trung quá giờ! Bạn có muốn cập nhật lịch để phản ánh đúng thời gian thực tế không?'},
    'update_calendar': {AppLocale.en: 'Update Calendar', AppLocale.vi: 'Cập nhật lịch'},
    'mark_complete': {AppLocale.en: 'Mark as Complete', AppLocale.vi: 'Đánh dấu hoàn thành'},
    'error_title': {AppLocale.en: 'Error', AppLocale.vi: 'Lỗi'},
    'min_suffix': {AppLocale.en: 'm', AppLocale.vi: 'phút'},

    // Squads Screen
    'invite_friends': {AppLocale.en: 'Invite Friends', AppLocale.vi: 'Mời bạn bè'},
    'invite_desc': {AppLocale.en: 'Share this code with your friends so they can join your squad.', AppLocale.vi: 'Chia sẻ mã này với bạn bè để họ tham gia nhóm của bạn.'},
    'create_btn': {AppLocale.en: 'Create', AppLocale.vi: 'Tạo'},
    'create_squad': {AppLocale.en: 'Create Squad', AppLocale.vi: 'Tạo nhóm'},
    'create_squad_desc': {AppLocale.en: 'Start a new group.', AppLocale.vi: 'Bắt đầu một nhóm mới.'},
    'squad_name_placeholder': {AppLocale.en: 'Squad Name', AppLocale.vi: 'Tên nhóm'},
    'mode': {AppLocale.en: 'Mode', AppLocale.vi: 'Chế độ'},
    'mode_buddy': {AppLocale.en: 'Buddy (2 members)', AppLocale.vi: 'Đồng đội (2 thành viên)'},
    'mode_squad': {AppLocale.en: 'Squad (5 members)', AppLocale.vi: 'Nhóm (5 thành viên)'},
    'join_squad': {AppLocale.en: 'Join Squad', AppLocale.vi: 'Tham gia nhóm'},
    'join_squad_desc': {AppLocale.en: 'Enter the invite code from your friend.', AppLocale.vi: 'Nhập mã mời từ bạn bè của bạn.'},
    'invite_code_placeholder': {AppLocale.en: 'Invite Code (e.g. uuid)', AppLocale.vi: 'Mã mời (ví dụ: uuid)'},
    'join_btn': {AppLocale.en: 'Join', AppLocale.vi: 'Tham gia'},
    'buddies': {AppLocale.en: 'Buddies', AppLocale.vi: 'Đồng đội'},
    'leaderboard': {AppLocale.en: 'Leaderboard', AppLocale.vi: 'Bảng xếp hạng'},
    'total_xp': {AppLocale.en: 'Total XP', AppLocale.vi: 'Tổng XP'},
    'level_label': {AppLocale.en: 'Level', AppLocale.vi: 'Cấp độ'},
    'no_squad_yet': {AppLocale.en: 'No Squad Yet', AppLocale.vi: 'Chưa có nhóm nào'},
    'join_squad_prompt': {AppLocale.en: 'Join a squad to stay accountable and earn more XP together!', AppLocale.vi: 'Tham gia nhóm để cùng nhau giữ kỷ luật và kiếm thêm XP!'},
    'join_with_code': {AppLocale.en: 'Join with Code', AppLocale.vi: 'Tham gia bằng mã'},
    'friend_activity': {AppLocale.en: 'Friend Activity', AppLocale.vi: 'Hoạt động của bạn bè'},
    'mock_activity_1': {AppLocale.en: 'Alex completed "Read 20 pages"', AppLocale.vi: 'Alex đã hoàn thành "Đọc 20 trang"'},
    'mock_time_1': {AppLocale.en: '10m ago', AppLocale.vi: '10 phút trước'},
    'mock_activity_2': {AppLocale.en: 'Sam reached a 5-day streak on "Morning Jog"!', AppLocale.vi: 'Sam đã đạt chuỗi 5 ngày thói quen "Chạy buổi sáng"!'},
    'mock_time_2': {AppLocale.en: '1h ago', AppLocale.vi: '1 giờ trước'},
    'mock_activity_3': {AppLocale.en: 'Taylor joined Alpha Squad', AppLocale.vi: 'Taylor đã tham gia Nhóm Alpha'},
    'mock_time_3': {AppLocale.en: '2h ago', AppLocale.vi: '2 giờ trước'},

    // Seeded Habit Names
    'Morning Run': {AppLocale.en: 'Morning Run', AppLocale.vi: 'Chạy buổi sáng'},
    'Read 10 pages': {AppLocale.en: 'Read 10 pages', AppLocale.vi: 'Đọc 10 trang'},
    'Team Standup': {AppLocale.en: 'Team Standup', AppLocale.vi: 'Họp nhóm hàng ngày'},
    'Meditation': {AppLocale.en: 'Meditation', AppLocale.vi: 'Thiền định'},
    'Gym Workout': {AppLocale.en: 'Gym Workout', AppLocale.vi: 'Tập thể hình'},
    'Deep Work': {AppLocale.en: 'Deep Work', AppLocale.vi: 'Tập trung làm việc'},

    // Heatmap labels
    'mon': {AppLocale.en: 'Mon', AppLocale.vi: 'T2'},
    'wed': {AppLocale.en: 'Wed', AppLocale.vi: 'T4'},
    'fri': {AppLocale.en: 'Fri', AppLocale.vi: 'T6'},

    // Cosmetics
    'cosmetics_emojis_title': {AppLocale.en: 'Emojis', AppLocale.vi: 'Biểu tượng cảm xúc'},
    'cosmetics_emojis_desc': {AppLocale.en: 'React to squad activities with these emojis.', AppLocale.vi: 'Tương tác với các hoạt động trong nhóm bằng các biểu tượng này.'},
    'cosmetics_heatmap_colors_title': {AppLocale.en: 'Heatmap Colors', AppLocale.vi: 'Màu sắc Heatmap'},
    'cosmetics_heatmap_colors_desc': {AppLocale.en: 'Change your activity heatmap color.', AppLocale.vi: 'Thay đổi màu hiển thị cho biểu đồ hoạt động của bạn.'},
  };

  final AppLocale locale;
  AppTranslations(this.locale);

  String translate(String key) {
    return _keys[key]?[locale] ?? key;
  }

  String translateBackendError(String error) {
    if (error.contains("at least one digit") || error.contains("RequiresDigit")) {
      return locale == AppLocale.vi ? "Mật khẩu phải có ít nhất một chữ số ('0'-'9')." : "Passwords must have at least one digit ('0'-'9').";
    }
    if (error.contains("at least one uppercase") || error.contains("RequiresUpper")) {
      return locale == AppLocale.vi ? "Mật khẩu phải có ít nhất một chữ cái viết hoa ('A'-'Z')." : "Passwords must have at least one uppercase ('A'-'Z').";
    }
    if (error.contains("at least one lowercase") || error.contains("RequiresLower")) {
      return locale == AppLocale.vi ? "Mật khẩu phải có ít nhất một chữ cái viết thường ('a'-'z')." : "Passwords must have at least one lowercase ('a'-'z').";
    }
    if (error.contains("non-alphanumeric") || error.contains("RequiresNonAlphanumeric")) {
      return locale == AppLocale.vi ? "Mật khẩu phải có ít nhất một ký tự đặc biệt (ví dụ: @, #, \$, ...)." : "Passwords must have at least one non-alphanumeric character.";
    }
    if ((error.contains("at least") && error.contains("characters")) || error.contains("TooShort")) {
      return locale == AppLocale.vi ? "Mật khẩu phải dài ít nhất 6 ký tự." : "Passwords must be at least 6 characters.";
    }
    if (error.contains("already taken") || error.contains("DuplicateEmail")) {
      return locale == AppLocale.vi ? "Email này đã được sử dụng bởi tài khoản khác." : "Email is already taken.";
    }
    return error;
  }
}

final translationsProvider = Provider<AppTranslations>((ref) {
  final locale = ref.watch(localeProvider);
  return AppTranslations(locale);
});
