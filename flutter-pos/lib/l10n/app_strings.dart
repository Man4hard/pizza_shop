class AppStrings {
  final bool isUrdu;
  const AppStrings({this.isUrdu = false});

  // ── App ──────────────────────────────────────────────────────────
  String get appTitle => isUrdu ? 'احمد فاسٹ فوڈ' : 'Ahmed Fast Food';
  String get switchLang => isUrdu ? 'English' : 'اردو';

  // ── Navigation ───────────────────────────────────────────────────
  String get navPos => isUrdu ? 'پی او ایس' : 'POS';
  String get navPosLong => isUrdu ? 'نقطہ فروخت' : 'Point of Sale';
  String get navOrders => isUrdu ? 'آرڈرز' : 'Orders';
  String get navSales => isUrdu ? 'فروخت' : 'Sales';
  String get navSalesLong => isUrdu ? 'فروخت کی تاریخ' : 'Sales History';
  String get navDashboard => isUrdu ? 'ڈیش بورڈ' : 'Dashboard';
  String get navProducts => isUrdu ? 'مصنوعات' : 'Products';
  String get navProductsLong => isUrdu ? 'مصنوعات کا انتظام' : 'Manage Products';

  // ── Common ───────────────────────────────────────────────────────
  String get cancel => isUrdu ? 'منسوخ' : 'Cancel';
  String get delete => isUrdu ? 'حذف' : 'Delete';
  String get save => isUrdu ? 'محفوظ' : 'Save';
  String get retry => isUrdu ? 'دوبارہ کوشش' : 'Retry';
  String get close => isUrdu ? 'بند' : 'Close';
  String get print => isUrdu ? 'پرنٹ' : 'Print';
  String get yes => isUrdu ? 'ہاں' : 'Yes';
  String get no => isUrdu ? 'نہیں' : 'No';
  String get edit => isUrdu ? 'ترمیم' : 'Edit';
  String get errorStr => isUrdu ? 'خرابی' : 'Error';

  // ── POS Screen ───────────────────────────────────────────────────
  String get searchHint => isUrdu ? 'مصنوعات تلاش کریں...' : 'Search products...';
  String get allCategories => isUrdu ? 'تمام' : 'All';
  String get currentOrder => isUrdu ? 'موجودہ آرڈر' : 'Current Order';
  String get clearCart => isUrdu ? 'صاف' : 'Clear';
  String get cartEmpty => isUrdu ? 'ٹوکری خالی ہے' : 'Cart is empty';
  String get tapItemsToAdd => isUrdu ? 'اشیاء شامل کرنے کے لیے ٹیپ کریں' : 'Tap items to add them';
  String get total => isUrdu ? 'کل' : 'Total';
  String get addItemsToOrder => isUrdu ? 'آرڈر میں اشیاء شامل کریں' : 'Add items to order';
  String get placeOrder => isUrdu ? 'آرڈر دیں' : 'Place Order';
  String get noItemsFound => isUrdu ? 'کوئی چیز نہیں ملی' : 'No items found';
  String get customerInfo => isUrdu ? 'گاہک کی معلومات' : 'Customer Info';
  String get customerNameField => isUrdu ? 'گاہک کا نام (اختیاری)' : 'Customer Name (optional)';
  String get tableNumberField => isUrdu ? 'میز نمبر (اختیاری)' : 'Table Number (optional)';
  String get notesField => isUrdu ? 'نوٹس (اختیاری)' : 'Notes (optional)';
  String get continueBtn => isUrdu ? 'جاری رکھیں' : 'Continue';
  String get orderFailed => isUrdu ? 'آرڈر ناکام' : 'Order failed';
  String get errorLoadingData => isUrdu ? 'ڈیٹا لوڈ کرنے میں خرابی' : 'Error loading data';
  String get viewCart => isUrdu ? 'کارٹ دیکھیں' : 'View Cart';

  // ── Orders Screen ────────────────────────────────────────────────
  String get orders => isUrdu ? 'آرڈرز' : 'Orders';
  String get pending => isUrdu ? 'زیر التواء' : 'Pending';
  String get completed => isUrdu ? 'مکمل' : 'Completed';
  String get cancelled => isUrdu ? 'منسوخ شدہ' : 'Cancelled';
  String get viewBill => isUrdu ? 'بل دیکھیں' : 'View Bill';
  String get cancelOrder => isUrdu ? 'آرڈر منسوخ کریں' : 'Cancel Order';
  String get yesCancelIt => isUrdu ? 'ہاں، منسوخ' : 'Yes, Cancel';
  String get noOrdersFound => isUrdu ? 'کوئی آرڈر نہیں ملا' : 'No orders found';
  String cancelOrderQuestion(String num) =>
      isUrdu ? 'کیا آرڈر $num منسوخ کریں؟' : 'Cancel order $num?';

  // ── Sales Screen ─────────────────────────────────────────────────
  String get salesHistory => isUrdu ? 'فروخت کی تاریخ' : 'Sales History';
  String get totalRevenue => isUrdu ? 'کل آمدنی' : 'Total Revenue';
  String get filterByDate => isUrdu ? 'تاریخ سے فلٹر' : 'Filter by date';
  String get allTime => isUrdu ? 'تمام وقت' : 'All time';
  String get clearFilter => isUrdu ? 'فلٹر صاف' : 'Clear filter';
  String get noSales => isUrdu ? 'ابھی کوئی فروخت نہیں' : 'No sales yet';
  String get itemsLabel => isUrdu ? 'اشیاء' : 'items';
  String get tableLabel => isUrdu ? 'میز' : 'Table';
  String get cash => isUrdu ? 'نقد' : 'Cash';
  String get card => isUrdu ? 'کارڈ' : 'Card';
  String get digital => isUrdu ? 'ڈیجیٹل' : 'Digital';

  // ── Dashboard Screen ─────────────────────────────────────────────
  String get dashboard => isUrdu ? 'ڈیش بورڈ' : 'Dashboard';
  String get todaysRevenue => isUrdu ? 'آج کی آمدنی' : "Today's Revenue";
  String get totalOrders => isUrdu ? 'کل آرڈرز' : 'Total Orders';
  String get salesTodayByHour => isUrdu ? 'آج فی گھنٹہ فروخت' : 'Sales Today by Hour';
  String get topSellingProducts => isUrdu ? 'سب سے زیادہ فروخت' : 'Top Selling Products';

  // ── Products Screen ──────────────────────────────────────────────
  String get manageProducts => isUrdu ? 'مصنوعات کا انتظام' : 'Manage Products';
  String get categories => isUrdu ? 'زمرے' : 'Categories';
  String get products => isUrdu ? 'مصنوعات' : 'Products';
  String get addCategory => isUrdu ? 'زمرہ شامل کریں' : 'Add Category';
  String get addProduct => isUrdu ? 'مصنوع شامل کریں' : 'Add Product';
  String get editProductTitle => isUrdu ? 'مصنوع ترمیم کریں' : 'Edit Product';
  String get addNewProduct => isUrdu ? 'نئی مصنوع شامل کریں' : 'Add New Product';
  String get deleteProductTitle => isUrdu ? 'مصنوع حذف کریں' : 'Delete Product';
  String get nameLabel => isUrdu ? 'نام *' : 'Name *';
  String get priceLabel => isUrdu ? 'قیمت *' : 'Price *';
  String get descriptionLabel => isUrdu ? 'تفصیل' : 'Description';
  String get categoryLabel => isUrdu ? 'زمرہ' : 'Category';
  String get available => isUrdu ? 'دستیاب' : 'Available';
  String get categoryAdded => isUrdu ? 'زمرہ شامل ہو گیا!' : 'Category added!';
  String get categoryUpdated => isUrdu ? 'زمرہ اپ ڈیٹ ہو گیا!' : 'Category updated!';
  String get productSaved => isUrdu ? 'مصنوع محفوظ ہو گئی' : 'Product saved';
  String get updateFailed => isUrdu ? 'اپ ڈیٹ ناکام' : 'Update failed';
  String get deleteFailed => isUrdu ? 'حذف ناکام' : 'Delete failed';
  String get editCategoryTitle => isUrdu ? 'زمرہ ترمیم کریں' : 'Edit Category';
  String get addCategoryTitle => isUrdu ? 'زمرہ شامل کریں' : 'Add Category';
  String get editCategoryTooltip => isUrdu ? 'زمرہ ترمیم' : 'Edit category';
  String get deleteCategoryTooltip => isUrdu ? 'زمرہ حذف' : 'Delete category';
  String get failedToLoad => isUrdu ? 'لوڈ ناکام' : 'Failed to load';
  String get searchProducts => isUrdu ? 'مصنوعات تلاش کریں...' : 'Search products...';
  String get categoryNameLabel => isUrdu ? 'زمرے کا نام *' : 'Category Name *';
  String get chooseIcon => isUrdu ? 'آئیکن منتخب کریں (اختیاری)' : 'Choose an Icon (optional)';
  String get nameRequired => isUrdu ? 'نام ضروری ہے' : 'Name is required';
  String get priceRequired => isUrdu ? 'قیمت ضروری ہے' : 'Price is required';
  String get selectCategory => isUrdu ? 'زمرہ منتخب کریں' : 'Select category';

  String productCount(int count) =>
      isUrdu ? '$count مصنوع' : '$count product${count == 1 ? '' : 's'}';
  String hasProducts(int count) => isUrdu
      ? '$count مصنوعات ہیں — حذف نہیں ہو سکتا'
      : 'Has $count product${count == 1 ? '' : 's'} — cannot delete';
  String deleteProductConfirm(String name) => isUrdu
      ? 'کیا آپ "$name" کو حذف کرنا چاہتے ہیں؟\nیہ واپس نہیں ہو سکتا۔'
      : 'Are you sure you want to delete "$name"?\nThis cannot be undone.';
  String toggledProduct(String name, bool wasAvailable) => isUrdu
      ? '$name ${wasAvailable ? "غیر فعال" : "فعال"} ہو گئی'
      : '$name ${wasAvailable ? "disabled" : "enabled"}';
  String deletedProduct(String name) =>
      isUrdu ? '$name حذف ہو گئی' : '$name deleted';
  String activeCount(int n) =>
      isUrdu ? '$n فعال' : '$n active';
  String hiddenCount(int n) =>
      isUrdu ? '$n پوشیدہ' : '$n hidden';
  String catsCount(int n) =>
      isUrdu ? '$n زمرے' : '$n cats';

  // ── Bill Dialog ──────────────────────────────────────────────────
  String get customer => isUrdu ? 'گاہک' : 'Customer';
  String get subtotal => isUrdu ? 'ذیلی کل' : 'Subtotal';
  String get tax => isUrdu ? 'ٹیکس' : 'Tax';
  String get discount => isUrdu ? 'رعایت' : 'Discount';
  String get payment => isUrdu ? 'ادائیگی' : 'Payment';
  String get thankYou => isUrdu ? 'شکریہ!' : 'Thank you!';
  String get printComingSoon => isUrdu ? 'پرنٹ فیچر جلد آ رہا ہے!' : 'Print feature coming soon!';
  String receiptNumber(String num) =>
      isUrdu ? 'رسید نمبر #$num' : 'Receipt #$num';
  String get tableTitle => isUrdu ? 'میز' : 'Table';
  String get notesTitle => isUrdu ? 'نوٹس' : 'Notes';
}
