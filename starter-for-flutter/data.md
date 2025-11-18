Tentu, ini adalah format markdown untuk field-field yang Anda berikan.

### **`tenants`**

| Column name              | Type               | Indexed | Default value |
| :----------------------- | :----------------- | :------ | :------------ |
| $id                      | string             | ✔       | -             |
| name `required`          | string (Size: 30)  |         | -             |
| logoUrl                  | string (Size: 30)  |         | NULL          |
| owner_user_id `required` | string (Size: 35)  | ✔       | -             |
| description              | string (Size: 256) |         | NULL          |
| status                   | string (Size: 256) |         | NULL          |
| userId                   | string (Size: 35)  | ✔       | NULL          |
| qrCodeUrl                | string (Size: 25)  |         | NULL          |
| $createdAt               | datetime           |         | -             |
| $updatedAt               | datetime           |         | -             |

<br>

### **`products`**

| Column name             | Type                       | Indexed | Default value |
| :---------------------- | :------------------------- | :------ | :------------ |
| $id                     | string                     | ✔       | -             |
| tenant_id `required`    | string (Size: 256)         |         | -             |
| category_id `required`  | string (Size: 256)         |         | -             |
| name `required`         | string (Size: 256)         |         | -             |
| description             | string (Size: 256)         |         | -             |
| price `required`        | double (Min: 20, Max: 256) |         | -             |
| image_uri               | string (Size: 256)         |         | NULL          |
| is_available `required` | boolean                    |         | -             |
| $createdAt              | datetime                   |         | -             |
| $updatedAt              | datetime                   |         | -             |

<br>

### **`orders`**

| Column name             | Type                        | Indexed | Default value |
| :---------------------- | :-------------------------- | :------ | :------------ |
| $id                     | string                      | ✔       | -             |
| items `required`        | string (Size: 256)          |         | -             |
| totalPrice `required`   | double (Min: 256, Max: 256) |         | -             |
| status `required`       | string (Size: 256)          |         | -             |
| tenantId `required`     | string (Size: 256)          |         | -             |
| customerName `required` | string (Size: 256)          |         | -             |
| $createdAt              | datetime                    |         | -             |
| $updatedAt              | datetime                    |         | -             |

<br>

### **`categories`**

| Column name         | Type              | Indexed | Default value |
| :------------------ | :---------------- | :------ | :------------ |
| $id                 | string            | ✔       | -             |
| name `required`     | string (Size: 69) |         | -             |
| tenantId `required` | string (Size: 35) |         | -             |
| $createdAt          | datetime          |         | -             |
| $updatedAt          | datetime          |         | -             |
