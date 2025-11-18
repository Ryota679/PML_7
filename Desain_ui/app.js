const FAKE_DATA = {
    tenants: [
        { id: 1, name: "Soto Ayam Pak Min", description: "Soto ayam kampung asli.", logo: "https://via.placeholder.com/80", isOpen: true, totalRevenue: 0, contractEndDate: '2026-01-01' },
        { id: 2, name: "Nasi Goreng Bu Wati", description: "Spesialis nasi dan mie goreng.", logo: "https://via.placeholder.com/80", isOpen: true, totalRevenue: 0, contractEndDate: '2025-11-15' },
        { id: 3, name: "Kopi Kenangan Senja", description: "Kopi susu gula aren terbaik.", logo: "https://via.placeholder.com/80", isOpen: false, totalRevenue: 0, contractEndDate: '2026-03-20' },
    ],
    products: {
        1: [ // Produk untuk tenant ID 1
            { id: 101, name: "Soto Ayam Biasa", price: 15000, desc: "Soto dengan suwiran ayam.", available: true },
            { id: 102, name: "Soto Ayam Spesial", price: 20000, desc: "Porsi jumbo + telur.", available: true },
            { id: 103, name: "Es Teh Manis", price: 5000, desc: "Teh manis dingin segar.", available: false },
        ],
        2: [ // Produk untuk tenant ID 2
            { id: 201, name: "Nasi Goreng Ayam", price: 18000, desc: "Nasi goreng dengan ayam dan telur.", available: true },
            { id: 202, name: "Mie Goreng Seafood", price: 22000, desc: "Mie dengan udang dan cumi.", available: true },
        ],
    },
    orders: [], // Initialize as empty array
    categories: [
        { id: 1, name: "Makanan Berat" },
        { id: 2, name: "Minuman Dingin" },
        { id: 3, name: "Cemilan" },
    ],
    cart: [],
    invoices: {
        1: [
            { id: 'INV-001', date: '2025-10-01', amount: 500000, status: 'paid' },
            { id: 'INV-002', date: '2025-11-01', amount: 500000, status: 'unpaid' },
        ],
        2: [
            { id: 'INV-003', date: '2025-10-15', amount: 450000, status: 'paid' },
        ],
    }
};

// Load cart and orders from localStorage on initialization
loadCartFromLocalStorage();
loadOrdersFromLocalStorage();
loadTenantsFromLocalStorage(); // Load tenants data
loadCurrentBuyerNameFromLocalStorage();

window.currentBuyerName = ""; // Initialize current buyer name globally

function saveCartToLocalStorage() {
    localStorage.setItem('kantinDigitalCart', JSON.stringify(FAKE_DATA.cart));
}

function loadCartFromLocalStorage() {
    const storedCart = localStorage.getItem('kantinDigitalCart');
    if (storedCart) {
        FAKE_DATA.cart = JSON.parse(storedCart);
    }
}

function saveOrdersToLocalStorage() {
    localStorage.setItem('kantinDigitalOrders', JSON.stringify(FAKE_DATA.orders));
}

function loadOrdersFromLocalStorage() {
    const storedOrders = localStorage.getItem('kantinDigitalOrders');
    if (storedOrders) {
        FAKE_DATA.orders = JSON.parse(storedOrders);
    }
}

function saveTenantsToLocalStorage() {
    localStorage.setItem('kantinDigitalTenants', JSON.stringify(FAKE_DATA.tenants));
}

function loadTenantsFromLocalStorage() {
    const storedTenants = localStorage.getItem('kantinDigitalTenants');
    if (storedTenants) {
        const loadedTenants = JSON.parse(storedTenants);
        // Merge loaded tenants with default tenants to ensure all properties exist
        FAKE_DATA.tenants = FAKE_DATA.tenants.map(defaultTenant => {
            const loadedTenant = loadedTenants.find(t => t.id === defaultTenant.id);
            return loadedTenant ? { ...defaultTenant, ...loadedTenant } : defaultTenant;
        });
    }
}

function saveCurrentBuyerNameToLocalStorage(name) {
    localStorage.setItem('kantinDigitalBuyerName', name);
    window.currentBuyerName = name;
}

function loadCurrentBuyerNameFromLocalStorage() {
    const storedName = localStorage.getItem('kantinDigitalBuyerName');
    if (storedName) {
        window.currentBuyerName = storedName;
    }
}

function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
}

function navigateTo(path) {
    window.location.href = path;
}

// Cart functions
function addToCart(tenantId, productId, productName, price) {
    const item = FAKE_DATA.cart.find(item => item.productId === productId && item.tenantId === tenantId);
    if (item) {
        item.quantity++;
    } else {
        FAKE_DATA.cart.push({ tenantId, productId, productName, price, quantity: 1 });
    }
    saveCartToLocalStorage(); // Save cart after modification
    updateCartCount();
    console.log("Cart:", FAKE_DATA.cart);
}

function increaseQuantity(tenantId, productId) {
    const item = FAKE_DATA.cart.find(item => item.productId === productId && item.tenantId === tenantId);
    if (item) {
        item.quantity++;
        saveCartToLocalStorage();
        updateCartCount();
    }
}

function decreaseQuantity(tenantId, productId) {
    const item = FAKE_DATA.cart.find(item => item.productId === productId && item.tenantId === tenantId);
    if (item && item.quantity > 1) {
        item.quantity--;
        saveCartToLocalStorage();
        updateCartCount();
    } else if (item && item.quantity === 1) {
        removeItem(tenantId, productId);
    }
}

function removeItem(tenantId, productId) {
    FAKE_DATA.cart = FAKE_DATA.cart.filter(item => !(item.productId === productId && item.tenantId === tenantId));
    saveCartToLocalStorage();
    updateCartCount();
}

function getCart() {
    return FAKE_DATA.cart;
}

function clearCart() {
    FAKE_DATA.cart = [];
    saveCartToLocalStorage(); // Save cart after modification
    updateCartCount();
}

function updateCartCount() {
    const cartCountElement = document.getElementById('cart-count');
    if (cartCountElement) {
        const totalItems = FAKE_DATA.cart.reduce((sum, item) => sum + item.quantity, 0);
        cartCountElement.textContent = totalItems;
        cartCountElement.style.display = totalItems > 0 ? 'flex' : 'none';
    }
}

function placeOrder(buyerName) {
    if (FAKE_DATA.cart.length === 0) {
        alert("Keranjang belanja kosong!");
        return null;
    }

    saveCurrentBuyerNameToLocalStorage(buyerName); // Save buyer name

    const tenantOrders = {};
    FAKE_DATA.cart.forEach(item => {
        if (!tenantOrders[item.tenantId]) {
            tenantOrders[item.tenantId] = {
                tenantId: item.tenantId,
                tenantName: FAKE_DATA.tenants.find(t => t.id === item.tenantId).name,
                items: [],
                total: 0,
                itemCount: 0
            };
        }
        tenantOrders[item.tenantId].items.push(item);
        tenantOrders[item.tenantId].total += item.price * item.quantity;
        tenantOrders[item.tenantId].itemCount += item.quantity;
    });

    const newOrders = [];
    for (const tenantId in tenantOrders) {
        const order = tenantOrders[tenantId];
        const orderId = 'ORD-' + Math.random().toString(36).substr(2, 9).toUpperCase();
        FAKE_DATA.orders.push({
            id: orderId,
            tenantId: order.tenantId,
            tenantName: order.tenantName,
            status: "new",
            items: order.itemCount,
            total: order.total,
            buyerName: buyerName,
            details: order.items
        });
        newOrders.push(orderId);
    }

    saveOrdersToLocalStorage(); // Save orders after modification
    clearCart();
    alert("Pesanan berhasil dibuat!");
    return newOrders;
}

// New function to update order status and tenant revenue
function updateOrderStatus(orderId, newStatus) {
    const order = FAKE_DATA.orders.find(o => o.id === orderId);
    if (order) {
        // If an order is being marked as completed, add its total to the tenant's revenue
        if (newStatus === 'completed' && order.status !== 'completed') {
            const tenant = FAKE_DATA.tenants.find(t => t.id === order.tenantId);
            if (tenant) {
                tenant.totalRevenue += order.total;
                saveTenantsToLocalStorage(); // Save updated tenant data
            }
        }
        order.status = newStatus;
        saveOrdersToLocalStorage(); // Save updated orders data
    }
}

// Owner-specific functions
function getOwnerDashboardData() {
    const totalTenants = FAKE_DATA.tenants.length;
    const totalRevenue = FAKE_DATA.tenants.reduce((sum, tenant) => sum + tenant.totalRevenue, 0);
    const todaysOrders = FAKE_DATA.orders.filter(order => {
        // This is a simple check. For a real app, you'd use date-fns or similar
        const orderDate = new Date(); // Assuming orders are for today
        const today = new Date();
        return orderDate.toDateString() === today.toDateString();
    }).length;

    return { totalTenants, totalRevenue, todaysOrders };
}

function populateOwnerDashboard() {
    const data = getOwnerDashboardData();
    document.getElementById('total-tenants').textContent = data.totalTenants;
    document.getElementById('total-revenue').textContent = `Rp ${data.totalRevenue.toLocaleString('id-ID')}`;
    document.getElementById('todays-orders').textContent = data.todaysOrders;
}

function populateTenantList() {
    const tenantList = document.getElementById('tenant-list-body');
    if (tenantList) {
        tenantList.innerHTML = ''; // Clear existing list
        FAKE_DATA.tenants.forEach(tenant => {
            const contractEndDate = new Date(tenant.contractEndDate);
            const today = new Date();
            const diffTime = Math.abs(contractEndDate - today);
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

            const row = `
                <tr>
                    <td>${tenant.name}</td>
                    <td>tenant@example.com</td>
                    <td>${diffDays} hari</td>
                    <td>
                        <button class="btn btn-sm btn-success">Kirim Tagihan</button>
                        <button class="btn btn-sm btn-warning">Tambah Durasi</button>
                    </td>
                </tr>
            `;
            tenantList.innerHTML += row;
        });
    }
}

function populateInvoiceList(tenantId) {
    const invoiceList = document.getElementById('invoice-list-body');
    if (invoiceList) {
        invoiceList.innerHTML = ''; // Clear existing list
        const tenantInvoices = FAKE_DATA.invoices[tenantId] || [];
        tenantInvoices.forEach(invoice => {
            const row = `
                <tr>
                    <td>${invoice.id}</td>
                    <td>${invoice.date}</td>
                    <td>Rp ${invoice.amount.toLocaleString('id-ID')}</td>
                    <td><span class="status-${invoice.status}">${invoice.status}</span></td>
                    <td>
                        ${invoice.status === 'unpaid' ? '<button class="btn btn-sm btn-primary">Bayar</button>' : ''}
                    </td>
                </tr>
            `;
            invoiceList.innerHTML += row;
        });
    }
}

function updateContractDuration(tenantId) {
    const tenant = FAKE_DATA.tenants.find(t => t.id === tenantId);
    if (tenant) {
        const contractEndDate = new Date(tenant.contractEndDate);
        const today = new Date();
        const diffTime = Math.abs(contractEndDate - today);
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        document.getElementById('contract-duration').textContent = diffDays;
    }
}