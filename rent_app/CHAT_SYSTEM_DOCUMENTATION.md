# Firebase-Based Real-Time Chat System Documentation

## Overview
This document describes the comprehensive Firebase-based real-time chat system implemented for the marketplace app, providing OLX-style user-to-user messaging capabilities with product-specific conversations.

## Architecture

### Data Models

#### Chat Model (`lib/models/chat.dart`)
- **Purpose**: Represents a conversation between two users
- **Key Features**:
  - Participant management with user IDs and names
  - Unread message counting per participant
  - Product association for marketplace-specific chats
  - Automatic last message tracking
  - Firestore serialization support

```dart
Chat(
  id: String,
  participantIds: List<String>,
  participantNames: Map<String, String>,
  unreadCounts: Map<String, int>,
  lastMessage: String?,
  lastTimestamp: DateTime?,
  lastSenderId: String?,
  productId: String?,        // For product-specific chats
  productTitle: String?,
  productImageUrl: String?,
  createdAt: DateTime,
  updatedAt: DateTime,
)
```

#### Message Model (`lib/models/message.dart`)
- **Purpose**: Represents individual messages within chats
- **Supported Types**:
  - Text messages
  - Image messages (future implementation)
  - Product sharing messages
- **Features**:
  - Rich metadata support
  - Timestamp formatting utilities
  - Edit tracking
  - Message type enumeration

```dart
Message(
  id: String,
  chatId: String,
  senderId: String,
  senderName: String,
  receiverId: String,
  text: String,
  type: MessageType,
  timestamp: DateTime,
  metadata: Map<String, dynamic>?,
  isEdited: bool,
)
```

### Service Layer

#### ChatService (`lib/services/chat_service.dart`)
- **Purpose**: Comprehensive chat operations and real-time data management
- **Key Methods**:
  - `createOrGetProductChat()`: Create/retrieve product-specific chats
  - `sendMessage()`: Send text messages with FCM notifications
  - `sendProductMessage()`: Share product information in chat
  - `getUserChatsStream()`: Real-time stream of user conversations
  - `getMessagesStream()`: Real-time stream of chat messages
  - `markChatAsRead()`: Update unread message counts
  - `loadMoreMessages()`: Pagination support for message history

#### FCMService (`lib/services/fcm_service.dart`)
- **Purpose**: Firebase Cloud Messaging for push notifications
- **Features**:
  - FCM token management
  - Foreground/background notification handling
  - Local notification display
  - User notification preferences
  - Notification queue processing

### User Interface

#### Chat List Screen (`lib/screens/chat_list_screen.dart`)
- **Purpose**: Display all user conversations
- **Features**:
  - Real-time chat updates with StreamBuilder
  - Unread message count badges
  - Product context indicators
  - Search functionality (placeholder)
  - Dark theme consistency

#### Chat Detail Screen (`lib/screens/chat_detail_screen.dart`)
- **Purpose**: Individual conversation interface
- **Features**:
  - Real-time messaging with pagination
  - Product information banner
  - Message composition with auto-scroll
  - User avatar displays
  - Timestamp formatting
  - Loading states and error handling

### Marketplace Integration

#### Enhanced Product Cards (`lib/widgets/marketplace_listing_card.dart`)
- **Added Features**:
  - "Chat with Seller" button on each product
  - Integrated with chat system
  - Prevents self-messaging

#### Marketplace Screen Integration (`lib/screens/marketplace_home_screen.dart`)
- **New Features**:
  - Chat navigation in app menu
  - Product chat initiation
  - User authentication checks
  - Loading states for chat creation

## Security & Privacy

### Firestore Security Rules (`firestore.rules`)
```javascript
// Chat collection rules
match /chats/{chatId} {
  allow read, write: if isParticipant(chatId) || isAdmin();
  allow create: if isAuthenticated() && isValidChatCreation();
  
  match /messages/{messageId} {
    allow read, write: if isParticipant(chatId) || isAdmin();
    allow create: if isAuthenticated() && isValidMessage();
  }
}
```

**Key Security Features**:
- Users can only access chats they participate in
- Admin oversight capabilities
- Authenticated user requirements
- Data validation on creation

## Firebase Cloud Functions

### Notification Processing (`functions/index.js`)
- **processNotificationQueue**: Processes FCM notification queue
- **sendChatNotification**: Callable function for direct notifications
- **cleanupNotificationQueue**: Automatic cleanup of old notifications

### Key Features:
- Automatic retry mechanisms
- Error logging and tracking
- Notification preference respect
- Multi-platform support (iOS/Android)

## Real-Time Features

### Stream-Based Updates
- **Chat List**: Real-time conversation updates
- **Message Stream**: Live message delivery
- **Unread Counts**: Instant read status updates

### Performance Optimizations
- **Pagination**: Messages loaded in chunks (20 per page)
- **Efficient Queries**: Indexed Firestore queries
- **Memory Management**: Proper stream disposal
- **Image Optimization**: Lazy loading and error handling

## Notification System

### Push Notification Flow
1. **Message Sent**: User sends message
2. **FCM Integration**: ChatService triggers notification
3. **Cloud Function**: Processes notification queue
4. **Delivery**: Push notification sent to receiver
5. **User Interaction**: Tapping opens specific chat

### Notification Types
- **Product Chat**: "New message about [Product Name]"
- **Direct Chat**: "New message from [User Name]"
- **Message Preview**: Truncated message content

## Usage Examples

### Starting a Product Chat
```dart
// From marketplace listing card
onChatTap: () => _startProductChat(listing),

// In marketplace screen
Future<void> _startProductChat(MarketplaceListing listing) async {
  final chatId = await ChatService.createOrGetProductChat(
    otherUserId: listing.sellerId,
    otherUserName: listing.sellerName,
    product: listing,
  );
  
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => ChatDetailScreen(chatId: chatId),
  ));
}
```

### Sending Messages
```dart
await ChatService.sendMessage(
  chatId: widget.chatId,
  text: messageText,
  receiverId: receiverId,
);
```

### Real-Time Message Listening
```dart
StreamBuilder<List<Message>>(
  stream: ChatService.getMessagesStream(chatId: widget.chatId),
  builder: (context, snapshot) {
    final messages = snapshot.data ?? [];
    return ListView.builder(/* ... */);
  },
)
```

## Deployment Considerations

### Required Dependencies
```yaml
dependencies:
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
  cloud_firestore: ^4.13.6
  firebase_core: ^2.24.2
```

### Firestore Indexes
Required composite indexes:
- `chats`: `participantIds` (array) + `updatedAt` (desc)
- `messages`: `chatId` + `timestamp` (desc)

### Cloud Functions Deployment
```bash
cd functions
npm install
firebase deploy --only functions
```

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Service method functionality
- Utility functions

### Integration Tests
- End-to-end message flow
- Notification delivery
- Real-time synchronization

### Manual Testing Scenarios
1. **Product Chat Flow**: Browse → Select Product → Chat → Send Message
2. **Notification Testing**: Background app → Receive message → Tap notification
3. **Offline Behavior**: Network disconnect → Reconnect → Message sync
4. **Multi-Device**: Same user on multiple devices → Message synchronization

## Performance Metrics

### Target Performance
- **Message Delivery**: < 500ms
- **Chat Loading**: < 1s for 20 messages
- **Real-time Updates**: < 200ms latency
- **Notification Delivery**: < 3s

### Monitoring
- Cloud Functions logs for notification success/failure
- Firestore query performance metrics
- User engagement analytics
- Error tracking and reporting

## Future Enhancements

### Planned Features
1. **Media Sharing**: Image and video messages
2. **Voice Messages**: Audio recording and playback
3. **Message Reactions**: Emoji reactions to messages
4. **Chat Moderation**: Automated content filtering
5. **Business Messaging**: Seller verification and business hours
6. **Message Translation**: Multi-language support
7. **Chat Backup**: Export conversation history

### Scalability Considerations
- Message archiving for old conversations
- Sharding for high-volume chats
- CDN integration for media files
- Regional data centers for global deployment

## Troubleshooting

### Common Issues
1. **Messages Not Appearing**: Check Firestore rules and user authentication
2. **Notifications Not Working**: Verify FCM token registration and Cloud Function deployment
3. **Real-time Issues**: Ensure proper stream disposal and network connectivity
4. **Permission Errors**: Validate user participation in chat

### Debug Tools
- Firebase Console for data inspection
- Cloud Functions logs for notification debugging
- Flutter dev tools for performance monitoring
- Network inspector for API calls

---

**Implementation Status**: ✅ Complete
**Last Updated**: December 2024
**Version**: 1.0.0
