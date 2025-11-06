erDiagram
    users {
        UUID id PK "Primary Key"
        String full_name
        String email "Unique"
        String password_hash
        ENUM role "owner, tenant, buyer"
    }

    tenants {
        UUID id PK "Primary Key"
        UUID owner_user_id FK "Foreign Key to users.id"
        String name
        String description
        ENUM status "active, inactive"
    }

    products {
        UUID id PK "Primary Key"
        UUID tenant_id FK "Foreign Key to tenants.id"
        INTEGER category_id FK "Foreign Key to categories.id"
        String name
        DECIMAL price
        BOOLEAN is_available
    }

    categories {
        INTEGER id PK "Primary Key"
        String name "Unique"
    }

    orders {
        UUID id PK "Primary Key"
        UUID buyer_user_id FK "Foreign Key to users.id"
        UUID tenant_id FK "Foreign Key to tenants.id"
        DECIMAL total_amount
        ENUM status "pending, preparing, etc."
    }

    order_items {
        INTEGER id PK "Primary Key"
        UUID order_id FK "Foreign Key to orders.id"
        UUID product_id FK "Foreign Key to products.id"
        INTEGER quantity
        DECIMAL price_at_purchase "Historical price"
    }

    users ||--|| tenants : "owns"
    users ||--o{ orders : "creates"
    tenants ||--o{ products : "sells"
    tenants ||--o{ orders : "receives"
    categories ||--o{ products : "categorizes"
    orders ||--o{ order_items : "contains"
    products ||--o{ order_items : "is part of"