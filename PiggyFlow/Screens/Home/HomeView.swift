import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("username") private var userName: String = ""
    @State private var expenseBottomSheet: Bool = false
    @State private var search: String = ""
    @State private var selectedFilter: FilterType = .month
    
    @Query private var expenses:[Expense]
    @Query private var incomes:[Income]

    @State private var editBottomSheet: Bool = false
    @State private var selectedTransactionForEdit: TransactionItem?
    
    // 🕒 Dynamic greeting based on time
        private var greeting: String {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12:
                return "Good Morning"
            case 12..<17:
                return "Good Afternoon"
            case 17..<22:
                return "Good Evening"
            default:
                return "Good Night"
            }
        }
    
    enum FilterType: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        
        var id: String { self.rawValue }
    }
    
    // Helper enum to wrap both Expense and Income
    enum TransactionItem: Identifiable {
        case expense(Expense)
        case income(Income)
        
        var id: String {
            switch self {
            case .expense(let e): return e.id
            case .income(let i): return i.id
            }
        }
        
        var date: Date {
            switch self {
            case .expense(let e): return e.date
            case .income(let i): return i.date
            }
        }
        
        var title: String {
            switch self {
            case .expense(let e): return e.name
            case .income: return "Income"
            }
        }
        
        var emoji: String {
            switch self {
            case .expense(let e): return e.emoji
            case .income: return "💰"
            }
        }
        
        var amount: String {
            switch self {
            case .expense(let e): return String(e.price)
            case .income(let i): return String(i.income)
            }
        }
        
        var note: String {
            switch self {
            case .expense(let e): return String(e.note)
            case .income: return " "
            }
        }
        
        var color: Color {
            switch self {
            case .expense: return .red
            case .income: return .green
            }
        }
    }
    
    // Combine and sort all transactions
    private var allTransactions: [TransactionItem] {
        let expenseItems = expenses.map { TransactionItem.expense($0) }
        let incomeItems = incomes.map { TransactionItem.income($0) }
        return (expenseItems + incomeItems).sorted { $0.date > $1.date }
    }

    // Filtered transactions (based on search + filter type)
    private var filteredTransactions: [TransactionItem] {
        let now = Date()
        
        // Step 1: Filter by date
        let dateFiltered = allTransactions.filter { item in
            switch selectedFilter {
            case .day:
                return item.date.isInSameDay(as: now)
            case .week:
                return item.date.isInSameWeek(as: now)
            case .month:
                return item.date.isInSameMonth(as: now)
            }
        }
        
        // Step 2: Apply search filter
        if search.isEmpty {
            return dateFiltered
        } else {
            return dateFiltered.filter { item in
                item.title.localizedCaseInsensitiveContains(search) ||
                item.note.localizedCaseInsensitiveContains(search)
            }
        }
    }

    
    // Total income
    private var totalIncome: Double {
        incomes.reduce(0) { $0 + $1.income }
    }

    // Total expenses (optional, if you want to show spent)
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment:.bottomTrailing){
                VStack{
                    HStack{
                        NavigationLink(destination: ProfileView()) {
                            Image("onboarding_image")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        VStack(alignment: .leading){
                            Text("\(greeting),")
                                .font(.system(size: 16, weight: .regular, design: .serif))
                            Text(userName)
                                .font(.system(size: 18, weight: .medium, design: .serif))
                        }
                        
                        Spacer()
                        
                        NavigationLink(destination: NotificationView()) {
                            VStack{
                                Image(systemName: "bell")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .clipShape(Circle())
                            }
                            .padding(.all, 12)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.1))
                                    .shadow(radius: 0.1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                        .frame(height: 24)
                    
                    VStack(alignment:.leading){
                        Text("Income")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .foregroundColor(Color.white)
                        Spacer()
                            .frame(height: 16)
                        
                        Text("\(totalIncome, specifier: "%.2f")")
                            .font(.system(size: 24, weight: .medium, design: .serif))
                            .foregroundColor(Color.white)
                        
                        Spacer()
                            .frame(height: 16)
                        
                        HStack{
                            VStack(alignment:.leading, spacing: 2){
                                HStack{
                                    Text("Spent")
                                        .font(.system(size: 16, weight: .regular, design: .serif))
                                        .foregroundColor(Color.red)
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.red)
                                        .frame(width: 12, height: 12)
                                }
                                Text("\(totalExpenses, specifier: "%.2f")")
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundColor(Color.white)
                            }
                            
                            Spacer()
                            
                            VStack(alignment:.leading, spacing:2){
                                HStack{
                                    Text("Left")
                                        .font(.system(size: 16, weight: .regular, design: .serif))
                                        .foregroundColor(Color.green)
                                    Image(systemName: "chart.line.downtrend.xyaxis")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(Color.green)
                                        .frame(width: 12, height: 12)
                                }
                                Text("\(totalIncome - totalExpenses, specifier: "%.2f")")
                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                    .foregroundColor(Color.white)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: colorScheme == .dark ? [Color.green.opacity(0.05), Color.green.opacity(0.05)] : [Color.black, Color.black.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    )

                    
                    Spacer()
                        .frame(height: 24)
                    
                    HStack(spacing:12){
                        TextField("Search", text: $search)
                            .padding(.leading, 40)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .shadow(radius: 0.5)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .overlay(
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12)
                                    Spacer()
                                }
                            )
                        
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(FilterType.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 10)
                        .frame(width: 120, height: 46)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .shadow(radius: 0.5)
                    }
                    .padding(.horizontal, 6)
                    
                    //                ScrollView {
                    //                    VStack(spacing: 12) {
                    //                        ForEach(expenses) { expense in
                    //                            ExpenseItemCard(emoji:expense.emoji, title: expense.name, date:expense.date, amount: String(expense.price), color: .red)
                    //                        }
                    //                        .onDelete(perform: deleteItem)
                    //                    }
                    //                    .padding(.horizontal, 8)
                    //                    .padding(.bottom, 10)
                    //                }
                    //                .safeAreaInset(edge: .bottom, spacing: 0) {
                    //                    Color.clear.frame(height: 0)
                    //                }
                    
                    if filteredTransactions.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "tray")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("No transactions yet")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("Tap the + button to add your first expense or income.")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                    } else {
                        
                        // Method 1 (with chevron)
//                        List {
//                            ForEach(allTransactions) { item in
//                                NavigationLink{
//                                    TransactionDetailView(item: item)
//                                } label:{
//                                    ExpenseItemCard(
//                                        emoji: item.emoji,
//                                        title: item.title,
//                                        date: item.date,
//                                        amount: String(item.amount),
//                                        color: item.color,
//                                        isIncome: item.color == .green
//                                    )
//                                }
//                                .buttonStyle(.plain)
//                                .listRowInsets(EdgeInsets())
//                                .padding(.vertical, 6)
//                                .padding(.horizontal, 4)
//                                .listRowSeparator(.hidden)
//                                .background(Color.clear)
//                                .listRowBackground(Color.clear)
//                            }
//                            .onDelete(perform: deleteItem)
//                        }
//                        .listStyle(.plain)
//                        .scrollContentBackground(.hidden)
                        
                        // Method 2 (without chevron)
                        List {
                            ForEach(filteredTransactions) { item in
                                ExpenseItemCard(
                                    emoji: item.emoji,
                                    title: item.title,
                                    date: item.date,
                                    amount: String(item.amount),
                                    color: item.color,
                                    isIncome: item.color == .green
                                )
                                .contentShape(Rectangle())
                                .background(
                                    NavigationLink(destination: TransactionDetailView(item: item)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                )
                                .listRowInsets(EdgeInsets())
                                .padding(.vertical, 6)
                                .padding(.horizontal, 4)
                                .listRowSeparator(.hidden)
                                .background(Color.clear)
                                .listRowBackground(Color.clear)
                            }
                            .onDelete(perform: deleteItem)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                    
                    
                }
                .padding(.horizontal)
                
                // Floating Action Button
                Button(action: {
                    expenseBottomSheet.toggle()
                }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green.gradient)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding()
                .sheet(isPresented: $expenseBottomSheet) {
                    AddExpenseBottomSheetView(itemToEdit: nil)
                }
                .sheet(isPresented: $editBottomSheet) {
                    if let item = selectedTransactionForEdit {
                        AddExpenseBottomSheetView(itemToEdit: item)
                    }
                }
            }
        }
    }
    
    private func deleteItem(at offsets: IndexSet){
        offsets.forEach { index in
            let item = allTransactions[index]
            switch item {
            case .expense(let expense):
                context.delete(expense)
            case .income(let income):
                context.delete(income)
            }
        }
        
        do{
            try context.save()
            print("Deleted Successfully")
        }catch {
            print("Failed to delete: \(error.localizedDescription)")
        }
    }
}

extension Date {
    func isInSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func isInSameWeek(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .weekOfYear)
    }

    func isInSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }
}

struct ExpenseItemCard: View {
    let emoji: String
    let title: String
    let date: Date
    let amount: String
    let color: Color
    let isIncome: Bool
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack {
            // Left side: Icon + Title
            HStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                    Text(formattedDate)
                        .font(.system(size: 13, weight: .light, design: .serif))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Right side: Price
            HStack(spacing: 4) {
                Image(systemName: "indianrupeesign")
                Text(amount)
                    .font(.system(size: 17, weight: .medium, design: .serif))
                Image(systemName: isIncome ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 13))
            }
            .foregroundColor(color)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
        )
    }
}


struct AddExpenseBottomSheetView: View{
    @Environment(\.dismiss) var expenseBottomSheetDismiss
    @Environment(\.modelContext) private var context
    
    @State private var showToast:Bool = false
    
    @State private var userCategories: [UserCategory] = []
    
    @State private var showAddCategorySheet: Bool = false
    
    @State private var selectedUserCategory: UserCategory? = nil
    @State private var newCategoryName: String = ""
    @State private var newCategoryEmoji: String = ""

    
    // Optional: If provided, we're in edit mode
    var itemToEdit: HomeView.TransactionItem?
    
    @State private var entryType: EntryType = .expense
    @State private var selectedCategory: CategoryType = .food
    @State private var price: String = ""
    @State private var dateValue: Date = Date()
    @State private var note: String = ""
    @State private var incomeText: String = ""
    
    
    // Computed property to determine if we're editing
    private var isEditMode: Bool {
        itemToEdit != nil
    }
    
    enum EntryType:String, CaseIterable, Identifiable {
        case expense = "Expense"
        case income = "Income"
        
        var id: String { self.rawValue }
    }
    
    enum CategoryType: String, CaseIterable, Identifiable {
        case food = "🍔 Food"
        case movie = "🎬 Movie"
        case ott = "📺 OTT"
        case groceries = "🛒 Groceries"
        case home = "🏠 Home"
        case transport = "🚌 Transport"
        case entertainment = "🎉 Entertainment"
        case drinks = "🍹 Drinks"
        case shopping = "🛍️ Shopping"
        case powerBill = "💡 Power Bill"
        case phone = "📱 Phone"
        case internet = "🌐 Internet"
        case fuel = "⛽ Fuel"
        case others = "🔖 Others"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Close button pinned at top right
            HStack {
                Spacer()
                Button(action: { expenseBottomSheetDismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 28, height: 28)
                        .foregroundColor(Color.red)
                        .padding()
                }
            }
            
            VStack(spacing:20){
                if !isEditMode {
                    Picker("Type", selection: $entryType) {
                        ForEach(EntryType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                if entryType == .expense {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        HStack{
                            Text("Select Category")
                                .font(.system(size: 16, weight: .regular, design: .serif))
                            
                            Spacer()
                            
                            // Add new category button
                            Button(action: {
                                showAddCategorySheet = true
                            }) {
                                Text("+ Add Category")
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 12)
                                    .font(.system(size: 16, weight: .regular, design: .serif))
                                    .foregroundColor(Color.white)
                                    .background(Color.green.gradient)
                                    .cornerRadius(10)
                            }
                            .sheet(isPresented: $showAddCategorySheet) {
                                ZStack{
                                    VStack(spacing: 20) {
                                        
                                        // Close button pinned at top right
                                        HStack {
                                            Spacer()
                                            Button(action: { showAddCategorySheet = false }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .resizable()
                                                    .frame(width: 28, height: 28)
                                                    .foregroundColor(Color.red)
                                                    .padding()
                                            }
                                        }
                                        VStack(spacing: 20) {
                                            Text("Add New Category")
                                                .font(.system(size: 24, weight: .semibold, design: .serif))
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Category Name")
                                                    .font(.system(size: 16, weight: .regular, design: .serif))
                                                
                                                TextField("Enter User Name", text: $newCategoryName)
                                                    .padding(12)
                                                    .background(Color.gray.opacity(0.1))
                                                    .cornerRadius(8)
                                                    .shadow(radius: 0.5)
                                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                            }
                                            .padding(.horizontal, 4)
                                            
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Emoji")
                                                    .font(.system(size: 16, weight: .regular, design: .serif))
                                                
                                                TextField("Emoji", text: $newCategoryEmoji)
                                                    .padding(12)
                                                    .background(Color.gray.opacity(0.1))
                                                    .cornerRadius(8)
                                                    .shadow(radius: 0.5)
                                                    .font(.system(size: 18, weight: .regular, design: .serif))
                                            }
                                            .padding(.horizontal, 4)
                                            
                                            HStack(spacing: 20) {
                                                
                                                Button {
                                                    showAddCategorySheet = false
                                                    newCategoryName = ""
                                                    newCategoryEmoji = "🔖"
                                                } label: {
                                                    Text("Cancel")
                                                        .frame(maxWidth: .infinity)
                                                        .font(.system(size: 18, weight: .medium, design: .serif))
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal)
                                                .foregroundColor(.white)
                                                .background(Color.red.gradient)
                                                .cornerRadius(10)
                                                
                                                Button {
                                                    addNewCategory()
                                                } label: {
                                                    Text("Add")
                                                        .frame(maxWidth: .infinity)
                                                        .font(.system(size: 18, weight: .medium, design: .serif))
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal)
                                                .foregroundColor(.white)
                                                .background(Color.green.gradient)
                                                .cornerRadius(10)
                                            }
                                            .padding(.top, 10)
                                            
                                            Spacer()
                                        }
                                        .padding()
                                        
                                        if showToast {
                                            VStack {
                                                Spacer()
                                                Text("⚠️ Fill Both Fields!")
                                                    .font(.body)
                                                    .padding(.horizontal, 20)
                                                    .padding(.vertical, 12)
                                                    .background(Color.black.opacity(0.85))
                                                    .foregroundColor(.white)
                                                    .cornerRadius(10)
                                                    .shadow(radius: 4)
                                                    .padding(.bottom, 50)
                                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                            }
                                            .animation(.easeInOut, value: showToast)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        
                        
                        
                        ScrollView(.vertical, showsIndicators: true) {
                            let columns = [GridItem(.flexible()), GridItem(.flexible())] // 2 columns
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(CategoryType.allCases) { category in
                                    Button(action: {
                                        selectedCategory = category
                                        selectedUserCategory = nil
                                    }) {
                                        Text(category.rawValue)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity) // full width in grid cell
                                            .foregroundColor(selectedCategory == category ? Color.white : Color.blue)
                                            .background(selectedCategory == category ? Color.green.opacity(0.8) : Color.gray.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                                
                                // User-added categories
                                ForEach(userCategories) { category in
                                    Button(action: {
                                        selectedUserCategory = category
                                        selectedCategory = .others
                                    }) {
                                        Text("\(category.emoji) \(category.name)")
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .frame(maxWidth: .infinity)
                                            .foregroundColor(selectedUserCategory?.id == category.id ? Color.white : Color.blue)
                                            .background(selectedUserCategory?.id == category.id ? Color.green.opacity(0.8) : Color.gray.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: 200)
                        .disabled(isEditMode)
                        
                    }
                    
                    // Price
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Price")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                        
                        TextField("e.g., 100", text: $price)
                            .keyboardType(.decimalPad)
                            .padding(.all, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 0.5)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                    }
                    
                    
                    DatePicker(selection: $dateValue, label: {
                        Text("Due Date")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                        
                    })
                    .padding(.all, 4)
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                        
                        TextEditor(text: $note)
                            .frame(height: 50)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 0.5)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .scrollContentBackground(.hidden)
                    }
                } else if entryType == .income{
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Income")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                        
                        TextField("e.g., 500", text: $incomeText)
                            .padding(.all, 12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 0.5)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                    }
                    
                    DatePicker(selection: $dateValue, label: {
                        Text("Due Date")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                        
                    })
                    .padding(.all, 4)
                    
                    // Note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.system(size: 16, weight: .regular, design: .serif))
                        
                        TextEditor(text: $note)
                            .frame(height: 50)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .shadow(radius: 0.5)
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .scrollContentBackground(.hidden)
                    }
                }
                
                
                Button{
                    if isEditMode {
                        // Update existing item
                        updateItem()
                    } else {
                        // Add new item
                        addNewItem()
                    }
                    expenseBottomSheetDismiss()
                } label: {
                    Text(isEditMode ? "Save Changes" : "Add")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .foregroundColor(.white)
                .background(Color.green.gradient)
                .cornerRadius(12)
                Spacer()
            }
            .padding()
        }
        .onAppear {
            if let item = itemToEdit {
                switch item {
                case .expense(let expense):
                    entryType = .expense
                    price = String(expense.price)
                    dateValue = expense.date
                    note = expense.note
                    // Set category based on emoji and name
                    if let category = CategoryType.allCases.first(where: { $0.rawValue == "\(expense.emoji) \(expense.name)" }) {
                        selectedCategory = category
                    }
                case .income(let income):
                    entryType = .income
                    incomeText = String(income.income)
                    dateValue = income.date
                    note = income.note
                }
            }
            
            UserCategoryManager.shared.fetchCategories()
            userCategories = UserCategoryManager.shared.categories
        }
    }
    
    // MARK: - Category Management
        private func addNewCategory() {
            let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedEmoji = newCategoryEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if both fields are filled
            guard !trimmedName.isEmpty, !trimmedEmoji.isEmpty else {
                withAnimation {
                    showToast = true
                }
                
                // Hide toast after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showToast = false
                    }
                }
                
                print("❌ Both fields are required.")
                return
            }
            
            print("🟢 Attempting to add new category:")
            print("🟢 Name: \(newCategoryName)")
            print("🟢 Emoji: \(newCategoryEmoji)")
            print("🟢 Current categories before adding: \(userCategories.count)")
            
            let newCategory = UserCategory(name: trimmedName, emoji: trimmedEmoji)
            
            let categoryContext = UserCategoryManager.shared.container.mainContext
            categoryContext.insert(newCategory)
            
            do {
                try categoryContext.save()
                
                print("✅ Category saved successfully!")
                print("✅ New category ID: \(newCategory.id)")
                
                UserCategoryManager.shared.fetchCategories()
                userCategories = UserCategoryManager.shared.categories
                print("✅ Total categories after save: \(userCategories.count)")

                
                // Verify the category was added
                userCategories.forEach { category in
                    print("✅ Available category: \(category.emoji) \(category.name)")
                }
                
                selectedUserCategory = newCategory
                newCategoryName = ""
                newCategoryEmoji = ""
                showAddCategorySheet = false
                
            } catch {
                print("❌ Failed to save category: \(error.localizedDescription)")
                print("❌ Error details: \(error)")
            }
        }
    
    
    // Separate function to add new item
    private func addNewItem() {
        if entryType == .expense {
            guard let priceValue = Double(price) else { return }
            
            let (emojiPart, namePart) = selectedUserCategory != nil ?
            (selectedUserCategory!.emoji, selectedUserCategory!.name) :
            (selectedCategory.rawValue.split(separator: " ").first.map(String.init) ?? "💸",
             selectedCategory.rawValue.split(separator: " ").dropFirst().first.map(String.init) ?? "Other")
            
            let newExpense = Expense(
                emoji: emojiPart,
                name: namePart,
                price: priceValue,
                date: dateValue,
                note: note
            )
            context.insert(newExpense)
        } else {
            guard let incomeValue = Double(incomeText) else { return }
            
            let newIncome = Income(
                income: incomeValue,
                date: dateValue,
                note: note
            )
            context.insert(newIncome)
        }
        
        do {
            try context.save()
            print("✅ Data saved successfully!")
        } catch {
            print("❌ Failed to save: \(error.localizedDescription)")
        }
    }
    
    // Separate function to update existing item
    private func updateItem() {
        guard let item = itemToEdit else { return }
        
        switch item {
        case .expense(let expense):
            if let priceValue = Double(price) {
                expense.price = priceValue
                expense.date = dateValue
                expense.note = note
            }
        case .income(let income):
            if let incomeValue = Double(incomeText) {
                income.income = incomeValue
                income.date = dateValue
                income.note = note
            }
        }
        
        do {
            try context.save()
            print("✅ Updated successfully!")
        } catch {
            print("❌ Failed to update: \(error.localizedDescription)")
        }
    }
}

#Preview{
    HomeView()
}
