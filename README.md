---

# **DataSockets**

*A high-level wrapper for QuickNetwork that handles player data loading, fallbacks, rule checks, serialization, deserialization, and wipe requests — all automatically.*

---

## **✨ What is DataSockets?**

DataSockets is a plug-and-play data pipeline built on top of **QuickNetwork**.
It provides a safe, consistent, and fully-managed workflow for:

* Player data loading
* Data reconciliation
* Data corruption fallback handling
* Automatic serialization/deserialization of complex datatypes
* Player rule enforcement (account age, restrictions, etc.)
* Automatic cleanup via Trove
* Server-side data wipe & reload requests

It abstracts away the “annoying parts” of data management so your game can focus on gameplay.

---

## **🚀 Features**

* **Automatic player load + reconciliation**
* **Automatic fallback handling** (`loadBackup`)
* **CFrame + Color3 serialization/deserialization**
* **Rule-checking system with kick messages**
* **Data wipe and data request API**
* **Trove-based memory management**
* **Signals for:**

  * `onDataChanged`
  * `onPlayerDataConstructed`
  * `onDataRequested`
  * `onWipeRequested`

---

## **📦 Installation**

Place the `DataSockets` module into any server-accessible location (typically `ServerScriptService` or a dedicated `Server/Modules` folder).
Import and use it like any other TS module:

```ts
import DataSockets from "path/to/DataSockets";
```

---

## **🧱 Architecture Overview**

DataSockets consists of three major layers:

### **1. Network Layer**

Handles QuickNetwork setup:

* Imports the configured network from `DataOptions`
* Provides fallback behavior (`loadBackup`)
* Emits `onDataChanged` whenever QuickNetwork updates data

### **2. PlayerData Layer**

Handles:

* Listening for players
* Loading / reconciling data
* Running rule checks
* Managing player-specific Troves
* Firing `onPlayerDataConstructed`

This layer also handles saving & cleaning up when players leave.

### **3. DataSockets Layer (Public API)**

This is the layer you interact with in your code.

* `requestDataAsync(player)`
* `requestWipeAsync(player)`
* Signals:

  * `onDataRequested`
  * `onWipeRequested`

---

## **📝 Usage Example**

### **Getting a player’s data**

```ts
import DataSockets from "server/DataSockets";

game.Players.PlayerAdded.Connect((player) => {
	const data = DataSockets.requestDataAsync(player);
	if (!data) return;

	print("Player data loaded:", data.Get());
});
```

---

### **Listening for data changes**

```ts
DataSockets.onDataChanged.Connect((player, key, newValue) => {
	print(`${player.Name} changed ${key} to:`, newValue);
});
```

---

### **Wiping player data**

```ts
const success = DataSockets.requestWipeAsync(player);
if (success) {
	print("Wipe completed");
} else {
	warn("Failed to wipe data");
}
```

---

## **🧩 Serialization / Deserialization**

DataSockets automatically converts complex Roblox objects into JSON-safe tables and back.

Supports:

* `CFrame`
* `Color3`
* (Easily extendable)

Example format:

```ts
{
	Position = { X = 0, Y = 5, Z = 12 },
	Rotation = { X = 90, Y = 0, Z = 180 },
}
```

---

## **🛡 Rule System**

DataSockets checks the player against your rule set (account age, etc.) before loading data.

If a rule is broken:

```ts
const [serverMessage, playerMessage] = ruleBreak(player, ruleId);
```

Player receives your message → kicked
Server logs your message → Warn()

---

## **🧼 Cleanup**

Each player is assigned a Trove:

* All connections
* Promises
* Signals
* DataObjects

are cleaned automatically on leave.

---

## **📁 Folder Structure**

```
DataSockets
 ├─ DataControls
 │   ├─ DataOptions
 │   ├─ DataStructure
 │   ├─ DataFormat
 │   └─ DataRules
 ├─ Utils
 ├─ @shared
 │   ├─ Trove
 │   ├─ Signal
 │   └─ QuickNetwork
 └─ DataSockets.luau / .ts
```
---
