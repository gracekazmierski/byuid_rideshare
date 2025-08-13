# RexRide

RexRide is a cross-platform rideshare application built for the BYU–Idaho community. Students can connect with each other to share rides, reduce costs, and foster connections — all while maintaining control over their privacy and safety.

---

## Features

### **Authentication & Profiles**
- Firebase Authentication: Sign in with Google, Email/Password, or Apple ID  
- BYUI Student Verification via school email  
- Profile management: add/update profile photo, personal info, and privacy settings  
- Public profiles display name, profile picture, and selected contact info (email, phone, Facebook username)

### **Ride Flow**
**Drivers**  
- Post ride offerings (To/From, date, time, seats, optional fare)  
- Accept or deny rider requests  
- Manage ride participants and group chat  

**Riders**  
- Browse and request to join available rides  
- Post ride requests (To/From, date) to find potential drivers  
- Join other riders’ requests to signal demand  

### **Communication**
- In-app group chats for confirmed rides  
- Messaging restricted to ride participants for safety  

### **Reviews & Ratings**
- Post-ride rating system for both drivers and riders  
- Optional written feedback  
- Publicly viewable review history on user profiles  

---

## Tech Stack

### **Frontend**
- Flutter/Dart (cross-platform mobile development)  
- Android Studio for Android development & emulation  
- Xcode for iOS development & testing  

### **Backend & Services**
- Firebase Authentication  
- Firestore (User, Ride, and Review databases)  
- Firebase Storage (profile photos)  
- Firebase Functions (JavaScript) for backend logic  
- Firebase App Check for iOS, Android, and Web  

### **Build Tools**
- Gradle (Android)  
- JavaScript for Firebase Functions and Web  

---

## Architecture Overview
- **Data Storage:**  
  - `users` collection for profiles and verification  
  - `rides` collection for ride offerings  
  - `rideRequests` collection for ride requests  
  - `reviews` collection for ratings and feedback  

- **Core Logic:**  
  - Trigger-based Firebase Functions handle ride lifecycle events  
  - Firestore rules enforce role-based access (rider/driver)  
  - App Check protects against unauthorized API calls  

---

## Roadmap
- Location-based ride suggestions  
- Push notifications for ride updates  
- Advanced filtering & search for rides  
- Payment integration for fares  

---
