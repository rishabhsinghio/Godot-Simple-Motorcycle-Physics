# 🏍️ Godot Easy Motorcycle Physics  
**RayCast-based motorcycle physics system for Godot Engine 4**

Godot Easy Motorcycle Physics is a **lightweight, beginner-friendly motorcycle physics system** built using **RayCast-based wheel detection**.  
It is designed to be **easy to understand, easy to integrate**, and **stable for gameplay**, making it ideal for learning vehicle physics or quickly adding motorcycle mechanics to your Godot project.

This system focuses on **game-ready behavior**, not heavy real-world simulation, while still providing believable riding dynamics.

---
## Godot Asset Library

- **Category:** 3D / Physics / RigidBody3D
- **Godot Version:** 4.5
- **Asset Type:** Addon
- **License:** MIT
  
## ✨ Features

- 🛞 **RayCast-based wheel physics**
- 🎮 **Fully input-driven motorcycle control**
- 🔄 Steering and leaning logic
- ⚖️ Stable balance system
- 🔧 Easy to integrate into existing motorcycles
- 🧠 Clean node-based setup (no complex math required)
- 🚀 Works with **Godot Engine 4.5**

---

## 🧠 Core Concept (How It Works)

Instead of using complex wheel colliders or vehicle bodies, this system uses:

- **RayCast3D nodes** to simulate wheel contact with the ground  
- **Forces and rotations** applied to the motorcycle body
- **Front and rear wheel separation** for realistic braking and steering behavior

This approach provides:
- Better stability
- Easier debugging
- Full control over behavior
- Compatibility with custom bike models

---

## 📦 Project Overview

- `motorcycle.tscn` contains the **complete motorcycle physics setup**
- No external dependencies
- Can be used as a **standalone demo** or integrated into any project

---

## 🚀 How to Use

### Option 1: Use the Ready-Made Motorcycle

The file:


Already includes:
- Physics logic
- RayCasts
- Steering and braking behavior

👉 Simply instance it into your scene and assign inputs.

---

### Option 2: Apply Physics to Your Own Motorcycle Model

Follow these steps carefully:

### 1️⃣ Create the Motorcycle Root

- Add a **Motorcycle** Node
- Name it something like `Motorcycle`

---

### 2️⃣ Add Collision

- Add a **CollisionShape3D**
- Set an appropriate shape for the bike body

---

### 3️⃣ Front Wheel Setup (Handle Bar)

1. Add a **Node3D** named: `handle_bar`
2. Inside it add:
- **RayCast3D** → for front wheel ground detection
- **Node3D** → represents the front tyre (visual or logical)

---

### 4️⃣ Rear Wheel Setup

1. Add a **RayCast3D** for rear wheel ground detection
2. Add a **Node3D** as a child for the rear tyre

---

### 5️⃣ Inspector Assignment

- Assign all required nodes (front raycast, rear raycast, handle bar, tyres) in the **Inspector**
- Ensure RayCasts point downward and are enabled

Once assigned, the physics system will automatically control:
- Acceleration
- Steering
- Leaning
- Braking

---

## 🎮 Input Methods

You must define the following input actions in **Project Settings → Input Map**:

| Action Name | Description |
|------------|------------|
| `Steer Left` | Lean and steer left |
| `Steer Right` | Lean and steer right |
| `Throttle` | Accelerate forward |
| `Reverse` | Move backward |
| `Clutch` | Engine disengage |
| `Front Brake` | Front wheel braking |
| `Rear Brake` | Rear wheel braking |
| `Shift Up` | Increase gear |
| `Shift Down` | Decrease gear |

> You are free to map these actions to keyboard, controller, or mobile inputs.

---

## ⚙️ Design Goals

- ✔ Easy setup (node-based, no math-heavy configuration)
- ✔ Stable gameplay physics
- ✔ Fully customizable
- ✔ Suitable for mobile and PC
- ✔ Beginner-friendly

---
## 📜 License

This project is open source.  
You are free to:
- Use it in personal or commercial projects
- Modify and redistribute it
- Learn and experiment freely

---

## 👤 Author

Created by **Rishabh Singh**  
Focused on learning, experimenting, and building practical vehicle physics systems in Godot.

---

