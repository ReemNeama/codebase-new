graph TD
    %% Entry Points with custom styling
    AppStart([🚀 App Start]):::startEnd --> AuthWrapper

    %% Auth Components with enhanced styling
    AuthWrapper{🔐 AuthWrapper}:::auth --> |Not Authenticated| LoginPage
    AuthWrapper -->|Authenticated| MainLayout
    
    %% Login Flow with better visual organization
    LoginPage[📝 Login Page]:::page --> |Success| AuthProvider
    LoginPage --> |Error| ShowError[❌ Show Error]:::error
    ShowError --> LoginPage
    
    %% Auth Provider & Token Management
    AuthProvider[👤 Auth Provider]:::auth -->|Update State| AuthState[🔄 Auth State]:::auth
    AuthProvider -->|Store Token| TokenManager[🎫 Token Manager]:::auth
    TokenManager -->|Secure Storage| SecureStorage[(💾 Secure Storage)]:::storage
    
    %% Main Navigation with icons
    MainLayout{📱 Main Layout}:::layout --> |"Tab 1"| HomePage
    MainLayout --> |"Tab 2"| AppStorePage
    MainLayout --> |"Tab 3"| RepositoryList
    MainLayout --> |"Tab 4"| MyProjects
    MainLayout --> |"Tab 5"| ProfilePage
    
    %% Protected Routes with consistent styling
    HomePage[🏠 Home Page]:::page -->|Guard| AuthGuard1
    AppStorePage[🏪 App Store]:::page -->|Guard| AuthGuard2
    RepositoryList[📚 Repositories]:::page -->|Guard| AuthGuard3
    MyProjects[📂 My Projects]:::page -->|Guard| AuthGuard4
    ProfilePage[👤 Profile]:::page -->|Guard| AuthGuard5
    
    %% Auth Guards grouped visually
    AuthGuard1{🛡️}:::guard -->|No Permission| UnauthorizedPage
    AuthGuard2{🛡️}:::guard -->|No Permission| UnauthorizedPage
    AuthGuard3{🛡️}:::guard -->|No Permission| UnauthorizedPage
    AuthGuard4{🛡️}:::guard -->|No Permission| UnauthorizedPage
    AuthGuard5{🛡️}:::guard -->|No Permission| UnauthorizedPage
    
    %% API Calls with clear flow
    SecureAPIClient([🔒 Secure API]):::api -->|Request| TokenManager
    SecureAPIClient -->|401 Error| RefreshToken[🔄 Refresh Token]:::auth
    RefreshToken --> TokenManager
    
    %% Permissions System
    AuthState -->|Check| Permissions{⚡ Permissions}:::auth
    Permissions -->|Grant/Deny| AuthGuard1
    Permissions -->|Grant/Deny| AuthGuard2
    Permissions -->|Grant/Deny| AuthGuard3
    Permissions -->|Grant/Deny| AuthGuard4
    Permissions -->|Grant/Deny| AuthGuard5
    
    %% MyProjects Tabs
    MyProjects -->|Tab 1| MyRepository[📁 My Repository]:::page
    MyProjects -->|Tab 2| MyApps[📱 My Apps]:::page
    
    %% Unauthorized Page
    UnauthorizedPage[🚫 Unauthorized]:::error
    
    %% Styling Classes
    classDef auth fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef page fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    classDef guard fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef storage fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef error fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef api fill:#e8eaf6,stroke:#1a237e,stroke-width:2px
    classDef layout fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef startEnd fill:#e0f2f1,stroke:#004d40,stroke-width:2px

# Enhanced Authentication and Navigation Flow

## Component Categories

### Entry Points 🚀
- **App Start**: Initial application launch
- **AuthWrapper**: Main authentication controller

### Authentication Components 🔐
- **Auth Provider**: Central authentication management
- **Auth State**: Authentication state tracking
- **Token Manager**: Secure token handling
- **Secure Storage**: Encrypted token storage

### Navigation Components 📱
- **Main Layout**: Bottom navigation container
- **Protected Pages**: Main application screens
- **Auth Guards**: Route protection system

### Pages 📑
- **Home Page**: Dashboard view
- **App Store**: Application marketplace
- **Repositories**: Code repository list
- **My Projects**: User's projects
  - My Repository: Personal repositories
  - My Apps: Personal applications
- **Profile**: User profile management

### Security Components 🛡️
- **Permissions System**: Access control
- **Secure API Client**: Protected API communication
- **Unauthorized Page**: Access denied handler

## Flow Descriptions

### Authentication Flow
1. 🚀 App Start
2. 🔐 Check Authentication
3. 📝 Login if needed
4. 📱 Access Main Layout

### Navigation Flow
1. 📱 Main Layout Access
2. 🛡️ Permission Check
3. ✅ Grant Access or ❌ Show Unauthorized

### API Communication
1. 🔒 Secure Request
2. 🎫 Token Validation
3. 🔄 Auto-Refresh if needed

### Permission System
1. ⚡ Check Permissions
2. 🛡️ Guard Validation
3. ✅ Allow or ❌ Deny Access

## Style Guide

### Colors
- 🔵 Auth Components: Light blue
- 🟢 Pages: Light green
- 🟡 Guards: Light orange
- 🔴 Storage: Light pink
- 🟣 Layout: Light purple
- ⚫ API: Light indigo
- 🌊 Start/End: Light teal

### Icons
- 🚀 Launch/Start
- 🔐 Security
- 📱 Navigation
- 📑 Pages
- 🛡️ Protection
- ❌ Error/Unauthorized
- 💾 Storage
- 🔄 Refresh/Update

This enhanced visualization provides a clearer and more visually appealing representation of the application's authentication and navigation flow.
