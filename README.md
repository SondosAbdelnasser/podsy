# podsy

A new Flutter project.

## Getting Started

##Directory Structure :
lib/
  models/                # Contains data models (Podcast, Episode, etc.)
  
    podcast_model.dart   # Defines the Podcast and Episode models
    
  providers/             # Contains providers for managing app state
  
    auth_provider.dart   # Auth provider (handles user login, signup, logout)
    
    podcast_provider.dart # Podcast provider (manages podcast data)
    
  services/              # Contains logic for interacting with Firebase
  
    auth_service.dart    # Auth service (handles Firebase Auth methods)
    
    podcast_service.dart # Podcast service (handles Firebase Firestore methods)
    
    firebase_service.dart # Firebase initialization and setup
    
  utils/                 # Helper functions and constants
  
    constants.dart       # Stores constants (e.g. admin email, app name)
    
    helpers.dart         # Helper functions (e.g. loading indicators)

    
  screens/               # Screens for the app's UI
    home_screen.dart     # Displays list of podcasts
    
    podcast_detail_screen.dart # Displays details of a selected podcast
    
    admin/               # Admin-specific screens
    
      admin_dashboard.dart # Admin dashboard for managing podcasts

      
    auth/                # Auth screens
    
      login_screen.dart   # Login screen
      
      signup_screen.dart  # Signup screen

      
  widgets/               # Reusable widgets
  
    podcast_card.dart    # Custom widget to display a podcast item
    
    
    episode_card.dart    # Custom widget to display an episode item
    
    custom_button.dart   # Reusable custom button widget
    
    podcast_list.dart    # List widget to display all podcasts
    
  main.dart              # Entry point of the app (initializes Firebase and providers)

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
