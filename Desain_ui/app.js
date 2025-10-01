const FAKE_DATA = {
    tenants: [
        { id: 1, name: "Soto Ayam Pak Min", description: "Soto ayam kampung asli.", logo: "https://via.placeholder.com/80", isOpen: true },
        { id: 2, name: "Nasi Goreng Bu Wati", description: "Spesialis nasi dan mie goreng.", logo: "https://via.placeholder.com/80", isOpen: true },
        { id: 3, name: "Kopi Kenangan Senja", description: "Kopi susu gula aren terbaik.", logo: "https://via.placeholder.com/80", isOpen: false },
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
    orders: [
        { id: 'ORD-001', tenantName: "Soto Ayam Pak Min", status: "new", items: 2, total: 35000, buyerName: "Rian" },
        { id: 'ORD-002', tenantName: "Nasi Goreng Bu Wati", status: "preparing", items: 1, total: 18000, buyerName: "Andi" },
        { id: 'ORD-003', tenantName: "Soto Ayam Pak Min", status: "ready", items: 1, total: 15000, buyerName: "Citra" },
    ],
    categories: [
        { id: 1, name: "Makanan Berat" },
        { id: 2, name: "Minuman Dingin" },
        { id: 3, name: "Cemilan" },
    ]
};

function getQueryParam(param) {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get(param);
}

function navigateTo(path) {
    window.location.href = path;
}