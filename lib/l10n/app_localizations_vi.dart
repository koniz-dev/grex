// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Grex';

  @override
  String get welcome => 'Chào mừng đến với Grex với Clean Architecture!';

  @override
  String get featureFlagsReady => 'Hệ thống Feature Flags đã sẵn sàng!';

  @override
  String get checkExamples =>
      'Xem các ví dụ trong feature_flags_example_screen.dart';

  @override
  String get login => 'Đăng nhập';

  @override
  String get register => 'Đăng ký';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get name => 'Tên';

  @override
  String get emailRequired => 'Vui lòng nhập email của bạn';

  @override
  String get emailInvalid => 'Vui lòng nhập địa chỉ email hợp lệ';

  @override
  String get passwordRequired => 'Vui lòng nhập mật khẩu';

  @override
  String passwordMinLength(int minLength) {
    return 'Mật khẩu phải có ít nhất $minLength ký tự';
  }

  @override
  String get nameRequired => 'Vui lòng nhập tên của bạn';

  @override
  String nameMinLength(int minLength) {
    return 'Tên phải có ít nhất $minLength ký tự';
  }

  @override
  String get dontHaveAccount => 'Chưa có tài khoản? Đăng ký';

  @override
  String get alreadyHaveAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get retry => 'Thử lại';

  @override
  String get error => 'Lỗi';

  @override
  String get loading => 'Đang tải...';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get spanish => 'Tiếng Tây Ban Nha';

  @override
  String get arabic => 'Tiếng Ả Rập';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get featureFlagsDebug => 'Gỡ lỗi Feature Flags';

  @override
  String get unexpectedError => 'Đã xảy ra lỗi không mong muốn';

  @override
  String get badRequest =>
      'Yêu cầu không hợp lệ. Vui lòng kiểm tra thông tin nhập vào.';

  @override
  String get unauthorized => 'Không được phép. Vui lòng đăng nhập lại.';

  @override
  String get forbidden => 'Bị cấm. Bạn không có quyền truy cập.';

  @override
  String get notFound => 'Không tìm thấy tài nguyên.';

  @override
  String get conflict => 'Xung đột. Tài nguyên đã tồn tại.';

  @override
  String get validationError =>
      'Lỗi xác thực. Vui lòng kiểm tra thông tin nhập vào.';

  @override
  String get tooManyRequests => 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';

  @override
  String get internalServerError => 'Lỗi máy chủ nội bộ. Vui lòng thử lại sau.';

  @override
  String get badGateway => 'Cổng kết nối không hợp lệ. Vui lòng thử lại sau.';

  @override
  String get serviceUnavailable =>
      'Dịch vụ không khả dụng. Vui lòng thử lại sau.';

  @override
  String get gatewayTimeout =>
      'Hết thời gian chờ cổng kết nối. Vui lòng thử lại sau.';

  @override
  String get clientError => 'Đã xảy ra lỗi phía máy khách.';

  @override
  String get serverError => 'Đã xảy ra lỗi máy chủ. Vui lòng thử lại sau.';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
      one: '1 mục',
      zero: 'Không có mục nào',
    );
    return '$_temp0';
  }

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phút trước',
      one: '1 phút trước',
      zero: 'Vừa xong',
    );
    return '$_temp0';
  }

  @override
  String get edit => 'Chỉnh sửa';

  @override
  String get delete => 'Xóa';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get add => 'Thêm';

  @override
  String get refresh => 'Làm mới';

  @override
  String get noItemsFound => 'Không tìm thấy mục nào';

  @override
  String get loadMore => 'Tải thêm';

  @override
  String get copyError => 'Sao chép lỗi';

  @override
  String get restart => 'Khởi động lại';

  @override
  String get errorOccurred => 'Đã xảy ra lỗi không mong muốn';

  @override
  String get errorDescription =>
      'Ứng dụng gặp phải lỗi không thể xử lý. Chúng tôi đã ghi nhận lỗi này và sẽ khắc phục trong phiên bản tiếp theo.';

  @override
  String get errorDetails => 'Chi tiết lỗi:';

  @override
  String get copyErrorSuccess => 'Đã sao chép chi tiết lỗi';

  @override
  String get contactSupport =>
      'Nếu lỗi vẫn tiếp tục, vui lòng liên hệ bộ phận hỗ trợ kỹ thuật.';

  @override
  String get close => 'Đóng';

  @override
  String get pageNotFound => 'Không tìm thấy trang';

  @override
  String get goToGroups => 'Đi đến Nhóm';

  @override
  String get addPayment => 'Thêm thanh toán';

  @override
  String get createPayment => 'Tạo thanh toán';

  @override
  String get paymentCreatedSuccess => 'Tạo thanh toán thành công';

  @override
  String get selectPayer => 'Vui lòng chọn người thanh toán';

  @override
  String get selectRecipient => 'Vui lòng chọn người nhận thanh toán';

  @override
  String get payerRecipientSame =>
      'Người thanh toán và người nhận không thể là cùng một người';

  @override
  String get paymentDetails => 'Chi tiết thanh toán';

  @override
  String get deletePayment => 'Xóa thanh toán';

  @override
  String get confirmDeletePayment =>
      'Bạn có chắc chắn muốn xóa thanh toán này không?';

  @override
  String get addFirstPayment => 'Thêm thanh toán đầu tiên';

  @override
  String get clearAll => 'Xóa tất cả';

  @override
  String get ascendingOrder => 'Thứ tự tăng dần';

  @override
  String get apply => 'Áp dụng';

  @override
  String get minAmountNegative => 'Số tiền tối thiểu không thể âm';

  @override
  String get maxAmountNegative => 'Số tiền tối đa không thể âm';

  @override
  String get minGreaterThanMax =>
      'Số tiền tối thiểu không thể lớn hơn số tiền tối đa';

  @override
  String get startAfterEnd => 'Ngày bắt đầu không thể sau ngày kết thúc';

  @override
  String get createNewGroup => 'Tạo nhóm mới';

  @override
  String get featureFlagsDebugTitle => 'Gỡ lỗi Feature Flags';

  @override
  String get clearAllOverrides => 'Xóa tất cả ghi đè';

  @override
  String get confirmClearOverrides =>
      'Bạn có chắc chắn muốn xóa tất cả ghi đè cục bộ không?';

  @override
  String get clear => 'Xóa';

  @override
  String get overridesCleared => 'Đã xóa tất cả ghi đè cục bộ';

  @override
  String get noFeatureFlags => 'Không tìm thấy feature flags';

  @override
  String get featureFlagsExamples => 'Ví dụ Feature Flags';

  @override
  String get newFeatureEnabled => 'Tính năng mới đã BẬT';

  @override
  String get newFeatureDisabled => 'Tính năng mới đã TẮT';

  @override
  String get noPayments => 'Không có thanh toán';

  @override
  String get paymentSummary => 'Tóm tắt thanh toán';

  @override
  String get totalPayments => 'Tổng số thanh toán';

  @override
  String get totalAmount => 'Tổng số tiền';

  @override
  String get errorLoadingPayments => 'Lỗi khi tải thanh toán';

  @override
  String get filterPayments => 'Lọc thanh toán';

  @override
  String get clearFilters => 'Xóa bộ lọc';

  @override
  String get filterAndSortPayments => 'Lọc & Sắp xếp thanh toán';

  @override
  String get dateRange => 'Khoảng ngày';

  @override
  String get amountRange => 'Khoảng số tiền';

  @override
  String get sortBy => 'Sắp xếp theo';

  @override
  String get startDate => 'Ngày bắt đầu';

  @override
  String get endDate => 'Ngày kết thúc';

  @override
  String get minAmount => 'Số tiền tối thiểu';

  @override
  String get maxAmount => 'Số tiền tối đa';

  @override
  String get selectDate => 'Chọn ngày';

  @override
  String get oldestToNewest => 'Cũ nhất đến mới nhất';

  @override
  String get newestToOldest => 'Mới nhất đến cũ nhất';

  @override
  String get amountRequired => 'Số tiền là bắt buộc';

  @override
  String get enterValidPositiveAmount => 'Nhập số tiền dương hợp lệ';

  @override
  String get currency => 'Tiền tệ';

  @override
  String get descriptionOptional => 'Mô tả (Tùy chọn)';

  @override
  String get whatWasPaymentFor => 'Thanh toán này dùng cho việc gì?';

  @override
  String get paymentDate => 'Ngày thanh toán';

  @override
  String get paymentParticipants => 'Người tham gia thanh toán';

  @override
  String get whoPaid => 'Ai đã thanh toán? *';

  @override
  String get whoReceivedPayment => 'Ai nhận thanh toán? *';

  @override
  String get cannotPaySelf =>
      'Một người không thể tự thanh toán cho chính mình. Vui lòng chọn người thanh toán và người nhận khác nhau.';

  @override
  String from(String name) {
    return 'Từ: $name';
  }

  @override
  String to(String name) {
    return 'Đến: $name';
  }

  @override
  String amount(String value) {
    return 'Số tiền: $value';
  }

  @override
  String description(String text) {
    return 'Mô tả: $text';
  }

  @override
  String date(String value) {
    return 'Ngày: $value';
  }

  @override
  String groupPayments(String groupName) {
    return 'Thanh toán $groupName';
  }

  @override
  String get enterPaymentAmount => 'Nhập số tiền thanh toán';

  @override
  String confirmDeletePaymentFrom(String payer, String recipient) {
    return 'Bạn có chắc chắn muốn xóa thanh toán này từ $payer đến $recipient?';
  }

  @override
  String get noPaymentsMatchCriteria =>
      'Không có thanh toán nào phù hợp với tiêu chí của bạn.';

  @override
  String get noPaymentsMatchSearch =>
      'Không có thanh toán nào phù hợp với tiêu chí tìm kiếm. Hãy thử điều chỉnh bộ lọc.';

  @override
  String get noPaymentsYet =>
      'Chưa có thanh toán nào. Thêm thanh toán đầu tiên để bắt đầu!';

  @override
  String get amountLabel => 'Số tiền *';

  @override
  String get exampleScreen => 'Màn hình ví dụ';

  @override
  String get exampleScreenContent => 'Nội dung màn hình ví dụ';
}
