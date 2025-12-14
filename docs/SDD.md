### 2. Software Design Document (SDD.md)
*(Peran diperbarui di seluruh dokumen)*

```markdown:Dokumen Desain Perangkat Lunak:SDD.md
### **Dokumen Desain Perangkat Lunak (SDD): Aplikasi Tenant QR-Order**

* **Versi:** 1.6
* **Tanggal:** 18 November 2025
* **Status:** Revisi (Memperbarui Role Enum)
* **Penyusun:** Gemini

---

### **1. Pendahuluan**

#### **1.1 Tujuan**
Dokumen ini menyediakan desain teknis yang komprehensif untuk Aplikasi Tenant QR-Order. Dokumen ini telah diperbarui untuk mencerminkan arsitektur peran yang baru: `owner_business`, `tenant`, dan `guest`.

---

### **2. Arsitektur Sistem Tingkat Tinggi (High-Level)**

Sistem ini akan mengadopsi arsitektur **Klien-BaaS (Backend as a Service)**, menggunakan Appwrite.

```mermaid
graph TD
    subgraph "Perangkat Pengguna"
        A[Aplikasi Mobile Flutter]
    end

    subgraph "Platform Appwrite"
        B[Appwrite SDK]
        C[Auth Service]
        D[Database Service]
        E[Functions Service]
        F[Realtime Service]
    end

    A -- HTTPS/WebSockets --> B
    B <--> C
    B <--> D
    B <--> E
    B <--> F