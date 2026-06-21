# EastHardware PMS (Product Management System)

A high-performance, local-first, peer-to-peer synchronized product, inventory, sales, and order management system designed for retail terminals. It runs completely offline or over a Local Area Network (LAN) with zero cloud reliance or subscription costs, providing small-to-medium businesses with complete ownership of their data.

---

## 🚀 Key Highlights & Architecture

### 1. Peer-to-Peer Subnetwork Synchronization
EastHardware PMS features a client-server architecture built on local networking.
* **Isolate-Based Servers**: The host terminal spawns background Dart Isolates to run concurrent HTTP and WebSocket servers (`shelf`) without blocking the Flutter UI thread.
* **Auto-Discovery**: Client terminals use `network_tools` and `network_info_plus` to scan the subnet IP range, automatically locating and connecting to the host machine.
* **Real-Time Reactive Blocs**: Any database update triggers a broadcast from the server's WebSocket, causing client-side BLoCs (hooked through a central `DependencyInjector`) to reload immediately and render updated data across all terminals.

### 2. SQLite JSON Proxy Database
A custom proxy pattern wraps database communications to unify developer workflow:
* **The Proxy**: Clients communicate using a `DatabaseServerProxy` that mirrors the standard SQFlite `Database` API. Rather than calling SQL directly on a local file, client DAOs invoke queries that are serialized into JSON and sent over WebSockets.
* **Atomic Processing Queue**: To prevent concurrency conflicts, database write requests are enqueued on the server side into a sequential, atomic `AsyncQueue` before execution on the underlying SQLite database (`sqflite_common_ffi`).

### 3. Custom Cryptographic Security
To maintain data integrity and prevent unauthorized access over shared local networks:
* **Pseudo-TLS Handshake**: Hosts and clients negotiate connections using an asymmetric key exchange (generated in a key-generation isolate via a custom cryptographic service).
* **Encrypted WebSockets**: After successful negotiation, a unique symmetric session key is shared, encrypting all subsequent JSON payloads and database queries transmitted over the WebSocket channel.

### 4. Predictive Inventory Analytics
The system embeds sophisticated inventory algorithms directly into SQLite using a complex database view (`product_status_view`):
* **Lead Time Demand**: Calculates how much inventory is consumed during average order wait times: `Avg Daily Sales * Avg Reorder Delay`.
* **Safety Stock**: Calculates a buffer using the formula: `(Max Daily Sales - Avg Daily Sales) * Avg Reorder Delay`.
* **Reorder Points**: Identifies exactly when to replenish stock: `Lead Time Demand + Safety Stock`.
* **Behavioral Tags**: Dynamically flags products as **Low Stock**, **Dead Stock**, or **Fast Moving** based on sales volume over rolling 14-day and 30-day windows.

### 5. Premium Fluent Desktop UI
Built with the Microsoft Fluent Design System (`fluent_ui`), providing a Windows 11-native experience:
* Multi-dimensional spreadsheet data tables (`two_dimensional_scrollables`).
* Visual revenue, restock, and sales charts using `fl_chart`.
* Advanced printing and PDF exporting of invoices and restock receipts (`pdf`, `printing`).
* Soft-deletion systems backed by an audit trail (`user_logs`) for high business compliance.

---

## 📂 Project Structure

```
easthardware_pms/
├── assets/                    # Image assets, icons, and logos
├── packages/                  # Custom or local library versions (fl_chart, window_manager_plus)
├── lib/
│   ├── app/                   # App window wrappers and Dependency Injection
│   ├── data/
│   │   └── database/          # SQLite helpers, DAOs (Data Access Objects), and Table definitions
│   ├── domain/
│   │   ├── backend/           # Shelf server host, WebSocket isolates, proxy database, encryption handshakes
│   │   ├── models/            # Domain models (Products, Users, Invoices, Orders, Payments, Logs)
│   │   └── repository/        # Clean architecture repository interfaces
│   ├── presentation/
│   │   ├── bloc/              # BLoC state management containers (auth, inventory, billing, server)
│   │   ├── cubit/             # Cubits for navigation and transient views
│   │   ├── views/             # Windows 11 Fluent UI screens (Billing, Inventory, Security, Settings)
│   │   └── widgets/           # Shared UI widgets (tables, chart panels, inputs)
│   ├── utils/                 # Asynchronous queues, network utilities, cryptography, extensions
│   └── main.dart              # Main application entry point (Initializes window parameters & background microservices)
└── test/                      # Unit and integration tests
```

---

## 🛠️ Tech Stack

* **Language**: Dart (SDK ^3.5.3) & Flutter
* **UI Framework**: Fluent UI (Windows 11 Fluent Design)
* **Local Database**: SQLite (`sqflite_common_ffi`)
* **State Management**: Bloc & Cubit (`flutter_bloc`, `bloc`)
* **Server Framework**: Shelf HTTP / Shelf WebSockets
* **Network Scan & Discovery**: `network_tools`, `network_info_plus`
* **Utility Libraries**: `async_queue`, `equatable`, `go_router`, `fl_chart`, `pdf`, `printing`

---

## ⚙️ Getting Started

### Prerequisites

1. **Flutter SDK**: Ensure you have Flutter installed (compatible with Dart `^3.5.3`).
2. **C Compiler / SQLite Development Libraries**: Required for desktop `ffi` compilation (Windows build tools).

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/water-mizuu/easthardware_pms.git
   cd easthardware_pms
   ```

2. Fetch all package dependencies:
   ```bash
   flutter pub get
   ```

3. Launch the application:
   ```bash
   flutter run -d windows
   ```

### Running Server & Client Terminals

* **Host Mode**: Go to the Network Settings view and select **Host Server**. The application will initialize the SQLite database file and start hosting the HTTP and WebSocket endpoints.
* **Client Mode**: Select **Connect to Host**. The client terminal will scan the subnetwork, perform a secure handshake, and link its UI dynamically to the host's database.
