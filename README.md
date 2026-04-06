    
art_learning_app/
    ├── backend/
    │   ├── src/
    │   │   ├── auth/
    │   │   │   ├── auth.controller.ts
    │   │   │   ├── auth.module.ts
    │   │   │   ├── auth.service.ts
    │   │   │   ├── jwt.strategy.ts
    │   │   │   └── dto/
    │   │   │       └── auth.dto.ts
    │   │   ├── users/
    │   │   │   ├── users.controller.ts
    │   │   │   ├── users.module.ts
    │   │   │   ├── users.service.ts
    │   │   │   └── dto/
    │   │   │       └── update-user.dto.ts
    │   │   ├── tutorials/
    │   │   │   ├── tutorials.controller.ts
    │   │   │   ├── tutorials.module.ts
    │   │   │   ├── tutorials.service.ts
    │   │   │   └── dto/
    │   │   │       ├── create-tutorial.dto.ts
    │   │   │       └── update-tutorial.dto.ts
    │   │   ├── artworks/
    │   │   │   ├── artworks.controller.ts
    │   │   │   ├── artworks.module.ts
    │   │   │   ├── artworks.service.ts
    │   │   │   └── dto/
    │   │   │       ├── create-artwork.dto.ts
    │   │   │       └── update-artwork.dto.ts
    │   │   ├── comments/
    │   │   │   ├── comments.controller.ts
    │   │   │   ├── comments.module.ts
    │   │   │   ├── comments.service.ts
    │   │   │   └── dto/
    │   │   │       └── create-comment.dto.ts
    │   │   ├── likes/
    │   │   │   ├── likes.controller.ts
    │   │   │   ├── likes.module.ts
    │   │   │   ├── likes.service.ts
    │   │   │   └── dto/
    │   │   │       └── like.dto.ts
    │   │   ├── notifications/
    │   │   │   ├── notifications.controller.ts
    │   │   │   ├── notifications.module.ts
    │   │   │   ├── notifications.service.ts
    │   │   │   └── dto/
    │   │   │       └── create-notification.dto.ts
    │   │   ├── prisma/
    │   │   │   └── prisma.service.ts
    │   │   ├── common/
    │   │   │   ├── guards/
    │   │   │   │   └── jwt-auth.guard.ts
    │   │   │   └── decorators/
    │   │   │       └── get-user.decorator.ts
    │   │   ├── app.module.ts
    │   │   └── main.ts
    │   ├── prisma/
    │   │   └── schema.prisma
    │   ├── .env
    │   ├── .gitignore
    │   ├── package.json
    │   ├── tsconfig.json
    │   └── nest-cli.json
    ├── frontend/
    │   ├── lib/
    │   │   ├── main.dart
    │   │   ├── screens/
    │   │   │   ├── home_screen.dart
    │   │   │   ├── tutorials_screen.dart
    │   │   │   ├── tutorial_detail_screen.dart
    │   │   │   ├── art_draw_screen.dart
    │   │   │   ├── explore_screen.dart
    │   │   │   ├── profile_screen.dart
    │   │   │   ├── edit_profile_screen.dart
    │   │   │   ├── login_screen.dart
    │   │   │   ├── register_screen.dart
    │   │   │   ├── saved_screen.dart
    │   │   │   ├── liked_screen.dart
    │   │   │   └── settings_screen.dart
    │   │   ├── widgets/
    │   │   │   ├── bottom_nav_bar.dart
    │   │   │   ├── tutorial_card.dart
    │   │   │   └── artwork_card.dart
    │   │   ├── providers/
    │   │   │   └── auth_provider.dart
    │   │   ├── services/
    │   │   │   ├── api_service.dart
    │   │   │   ├── auth_service.dart
    │   │   │   └── storage_service.dart
    │   │   ├── models/
    │   │   │   ├── tutorial.dart
    │   │   │   ├── artwork.dart
    │   │   │   └── user.dart
    │   │   └── utils/
    │   │       ├── colors.dart
    │   │       └── constants.dart
    │   ├── assets/
    │   │   └── images/   (thêm logo.png nếu có)
    │   ├── pubspec.yaml
    │   └── .gitignore
    └── database/
    └── create_tables.sql (bạn đã có)