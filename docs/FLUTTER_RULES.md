# SwapTunes — Flutter Frontend Rules

> Single source of truth for Claude Code and AI agents.
> Apply every rule in this file to every screen, widget, and ViewModel.

---

## 1. No Hardcoded Values

### Colors — always use theme tokens

```dart
// ❌
Container(color: Color(0xFF10b981))
Text("Hi", style: TextStyle(color: Colors.green))

// ✅
Container(color: Theme.of(context).colorScheme.primary)
Text("Hi", style: TextStyle(color: AppColors.primary))
```

### Strings — always use AppStrings

```dart
// ❌
Text("Welcome back")
hintText: "Search playlists..."

// ✅
Text(AppStrings.welcomeBack)
hintText: AppStrings.searchHint
```

### Numbers — named constants only

```dart
// ❌
SizedBox(height: 16)
BorderRadius.circular(12)
Duration(milliseconds: 300)
if (title.length > 50)

// ✅
SizedBox(height: AppSpacing.md)
BorderRadius.circular(AppRadius.card)
Duration(milliseconds: AppDurations.animShort)
if (title.length > AppConstants.maxTitleLength)
```

### URLs and API paths

```dart
// ❌
http.get(Uri.parse("https://api.swaptunes.com/feed"))

// ✅ — never call HTTP from a screen anyway; use a repository method
```

---

## 2. State Management — UI Not Updating

### Always call notifyListeners() after every mutation

```dart
// ❌
void addPost(Post post) {
  _posts.add(post);
}

// ✅
void addPost(Post post) {
  _posts = [..._posts, post]; // new reference + notify
  notifyListeners();
}
```

### Replace collections — never mutate in place

Provider compares object references. Mutating in place won't always trigger a rebuild.

```dart
// ❌
_posts.add(post);
_likedPostIds.add(postId);

// ✅
_posts = [..._posts, post];
_likedPostIds = {..._likedPostIds, postId};
```

### Replace nested objects using copyWith

```dart
// ❌ — same reference, widget never rebuilds
_user.followerCount = 100;
notifyListeners();

// ✅
_user = _user.copyWith(followerCount: 100);
notifyListeners();
```

### Guard notifyListeners() against calling after dispose

```dart
bool _disposed = false;

Future<void> fetchFeed() async {
  final data = await _repo.getFeed();
  if (!_disposed) {
    _posts = data;
    notifyListeners();
  }
}

@override
void dispose() {
  _disposed = true;
  super.dispose();
}
```

### context.watch vs context.read

```dart
// context.watch — inside build() only
final vm = context.watch<FeedViewModel>();

// context.read — inside callbacks only, never in build()
onPressed: () => context.read<FeedViewModel>().toggleLike(postId),

// ❌ Never
onPressed: () => context.watch<FeedViewModel>().toggleLike(postId),
```

---

## 3. Optimistic UI — Where to Use It and Where Not To

Update the UI instantly, call the API in the background, revert if it fails.

```
snapshot → update UI → call API → revert on failure
```

### Decision rule

> Use it when the action is a **toggle**, failure is **rare**, and the result is **predictable**.
> Skip it when the action is **irreversible**, **destructive**, or the result **depends on the server**.

### Where to use ✅

| Action                   | Why                                         |
| ------------------------ | ------------------------------------------- |
| Like / unlike a post     | Toggle, low failure rate, easy revert       |
| Follow / unfollow a user | Toggle, easy revert                         |
| Save / unsave a playlist | Toggle, easy revert                         |
| Send a chat message      | User already typed it — show it immediately |
| Read receipt / mark seen | Fire and forget, no revert needed           |

### Where NOT to use ❌

| Action                                           | Why                                                                   |
| ------------------------------------------------ | --------------------------------------------------------------------- |
| Create a post / upload                           | Server assigns ID and processes media — you don't know the result yet |
| Delete a post                                    | Destructive and irreversible — confirm first, wait for server         |
| Purchase / payment                               | Never optimise financial actions                                      |
| Auth (login, signup)                             | Result depends entirely on server validation                          |
| Creator profile setup                            | Multi-field form — wait for server confirmation                       |
| Any action that changes a server-generated value | e.g. rank, score, computed fields                                     |

### Implementation pattern

```dart
Future<void> toggleLike(String postId) async {
  // 1. Snapshot
  final wasLiked = _likedPostIds.contains(postId);
  final prevCount = _likeCounts[postId] ?? 0;

  // 2. Update UI instantly
  _likedPostIds = wasLiked
      ? {..._likedPostIds}..remove(postId)
      : {..._likedPostIds, postId};
  _likeCounts = {..._likeCounts, postId: wasLiked ? prevCount - 1 : prevCount + 1};
  notifyListeners();

  // 3. Call API
  try {
    await _repo.toggleLike(postId);
  } catch (e) {
    // 4. Revert on failure
    _likedPostIds = wasLiked
        ? {..._likedPostIds, postId}
        : {..._likedPostIds}..remove(postId);
    _likeCounts = {..._likeCounts, postId: prevCount};
    _errorMessage = AppStrings.genericError;
    notifyListeners();
  }
}
```

### Optimistic message sending

```dart
Future<void> sendMessage(String text) async {
  // Snapshot
  final tempId = const Uuid().v4();
  final optimisticMsg = Message(
    id: tempId,
    text: text,
    status: MessageStatus.sending,
    createdAt: DateTime.now(),
  );

  // Update UI
  _messages = [..._messages, optimisticMsg];
  notifyListeners();

  try {
    final confirmed = await _repo.sendMessage(text);
    // Replace temp message with confirmed one from server
    _messages = _messages
        .map((m) => m.id == tempId ? confirmed : m)
        .toList();
  } catch (e) {
    // Mark as failed — don't remove, let user retry
    _messages = _messages
        .map((m) => m.id == tempId
            ? m.copyWith(status: MessageStatus.failed)
            : m)
        .toList();
  }
  notifyListeners();
}
```

---

## 4. Exception Handling

### Always catch typed exceptions — never swallow errors

```dart
// ❌
try {
  await repo.fetchFeed();
} catch (e) {}

// ✅
try {
  await repo.fetchFeed();
} on NetworkException catch (e) {
  _errorMessage = e.message;
  notifyListeners();
} on CacheException {
  _errorMessage = AppStrings.cacheError;
  notifyListeners();
} catch (e) {
  _errorMessage = AppStrings.genericError;
  notifyListeners();
}
```

### Standard ViewModel async pattern

Every async method follows this structure — no exceptions.

```dart
Future<void> fetchFeed() async {
  if (_isLoading) return; // guard against duplicate calls
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    _posts = await _repository.getFeed();
  } catch (e) {
    _errorMessage = AppStrings.genericError;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

### Surface errors to the UI

```dart
@override
Widget build(BuildContext context) {
  final vm = context.watch<FeedViewModel>();

  if (vm.errorMessage != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage!)),
      );
      vm.clearError();
    });
  }
  ...
}
```

### Result type for operations that can fail gracefully

```dart
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}

// In repository
Future<Result<List<Post>>> getFeed() async {
  try {
    final data = await supabase.from('posts').select();
    return Success(data.map(Post.fromJson).toList());
  } catch (e) {
    return Failure(AppStrings.genericError);
  }
}

// In ViewModel
final result = await _repository.getFeed();
switch (result) {
  case Success(:final data): _posts = data;
  case Failure(:final message): _errorMessage = message;
}
notifyListeners();
```

---

## 5. Loading & UX States

Every data screen must handle all four states. AI always skips 2 and 3.

```dart
@override
Widget build(BuildContext context) {
  final vm = context.watch<FeedViewModel>();

  // 1. Loading — shimmer skeleton, not a spinner
  if (vm.isLoading && vm.posts.isEmpty) {
    return const FeedShimmer();
  }

  // 2. Error — always include a retry button
  if (vm.errorMessage != null && vm.posts.isEmpty) {
    return ErrorState(
      message: vm.errorMessage!,
      onRetry: () => vm.fetchFeed(),
    );
  }

  // 3. Empty — message, not just white space
  if (vm.posts.isEmpty) {
    return const EmptyState(message: AppStrings.noPostsYet);
  }

  // 4. Content
  return ListView.builder(...);
}
```

**Rules:**

- First load → shimmer skeleton that matches the content layout
- Pagination loading → small indicator at bottom of list, never full-screen
- Error state → always has a retry button
- Empty state → always has a message or illustration

---

## 6. Pagination

### Always paginate — never fetch all rows

```dart
// ❌
final data = await supabase.from('posts').select();

// ✅
final data = await supabase
    .from('posts')
    .select()
    .order('created_at', ascending: false)
    .range(_page * _pageSize, (_page + 1) * _pageSize - 1);
```

### Track end of list

```dart
bool _hasMore = true;

Future<void> fetchNextPage() async {
  if (_isLoadingMore || !_hasMore) return;
  _isLoadingMore = true;
  notifyListeners();

  try {
    final results = await _repo.getFeed(page: _page);
    if (results.length < _pageSize) _hasMore = false;
    _posts = [..._posts, ...results];
    _page++;
  } catch (e) {
    _errorMessage = AppStrings.genericError;
  } finally {
    _isLoadingMore = false;
    notifyListeners();
  }
}
```

### Scroll listener — always guard

```dart
scrollController.addListener(() {
  if (
    scrollController.position.atEdge &&
    scrollController.position.pixels != 0 && // not top
    !vm.isLoadingMore &&
    vm.hasMore
  ) {
    vm.fetchNextPage();
  }
});
```

### Reset pagination on refresh

```dart
Future<void> refresh() async {
  _page = 0;
  _hasMore = true;
  _posts = [];
  notifyListeners();
  await fetchNextPage();
}
```

---

## 7. Rate Limiting & Request Safety

### Debounce search input

```dart
Timer? _searchDebounce;

void onSearchChanged(String query) {
  _searchDebounce?.cancel();
  _searchDebounce = Timer(const Duration(milliseconds: 400), () {
    _search(query);
  });
}
```

### Per-item in-flight guard for action buttons

```dart
final Set<String> _pendingLikes = {};

Future<void> toggleLike(String postId) async {
  if (_pendingLikes.contains(postId)) return;
  _pendingLikes.add(postId);
  try {
    await _repo.toggleLike(postId);
  } finally {
    _pendingLikes.remove(postId);
    notifyListeners();
  }
}
```

### Disable submit button while loading

```dart
ElevatedButton(
  onPressed: vm.isLoading ? null : () => vm.submit(),
  child: vm.isLoading
      ? const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2))
      : const Text("Save"),
)
```

### Prevent double fetch on first load

```dart
bool _fetched = false;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_fetched) {
    _fetched = true;
    context.read<FeedViewModel>().fetchFeed();
  }
}
```

---

## 8. Security

### Never store sensitive data in SharedPreferences

```dart
// ❌ — plain text on disk
await prefs.setString('authToken', token);

// ✅
await secureStorage.write(key: 'authToken', value: token);
```

### Never log tokens, passwords, or PII

```dart
// ❌
print("Login response: ${response.body}");

// ✅
debugPrint("Login success: ${user.id}");
```

### Validate and trim all input before sending to API

```dart
// ❌
await _repo.updateProfile(bio: bioController.text);

// ✅
final bio = bioController.text.trim();
if (bio.length > AppConstants.maxBioLength) {
  _errorMessage = AppStrings.bioTooLong;
  notifyListeners();
  return;
}
await _repo.updateProfile(bio: bio);
```

### Never use the Supabase service role key in Flutter

```dart
// ❌ — bypasses all RLS policies
final supabase = SupabaseClient(url, serviceRoleKey);

// ✅
final supabase = SupabaseClient(url, anonKey);
```

---

## 9. Memory Leaks

### Always cancel stream subscriptions

```dart
StreamSubscription? _sub;

void subscribe() {
  _sub = supabase.channel('messages').stream(...).listen((_) {});
}

@override
void dispose() {
  _sub?.cancel();
  _disposed = true;
  super.dispose();
}
```

### Always dispose AnimationControllers

```dart
@override
void dispose() {
  _animController.dispose();
  super.dispose();
}
```

### Always cancel Timers

```dart
Timer? _timer;

@override
void initState() {
  super.initState();
  _timer = Timer.periodic(const Duration(seconds: 30), (_) => vm.refresh());
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

### Always dispose TextEditingControllers

```dart
@override
void dispose() {
  _nameController.dispose();
  _bioController.dispose();
  super.dispose();
}
```

---

## 10. Null Safety & Defensive Coding

### Null-safe chain access

```dart
// ❌
Text(vm.user.profile.avatarUrl)

// ✅
Text(vm.user?.profile?.avatarUrl ?? AppStrings.defaultAvatar)
```

### Empty list check before index access

```dart
// ❌
final first = vm.posts[0];

// ✅
final first = vm.posts.isNotEmpty ? vm.posts.first : null;
```

### mounted check after every async gap

```dart
// ❌
Future<void> onSubmit() async {
  await vm.save();
  Navigator.pop(context); // context may be invalid
}

// ✅
Future<void> onSubmit() async {
  await vm.save();
  if (!mounted) return;
  Navigator.pop(context);
}
```

---

## 11. Widget Best Practices

### Extract widgets — build() must stay short

```dart
// ❌ — 150-line build method
@override
Widget build(BuildContext context) {
  return Scaffold(body: Column(children: [ /* everything inline */ ]));
}

// ✅
@override
Widget build(BuildContext context) {
  return Scaffold(body: Column(children: [_Header(), _FeedList()]));
}
```

### const everywhere possible

```dart
// ✅
const SizedBox(height: AppSpacing.md)
const Icon(Icons.home)
const Text("Static label")
```

### Never pass mutable state as constructor props

```dart
// ❌ — goes stale when ViewModel updates
class PostCard extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  const PostCard({required this.isLiked, required this.likeCount});
}

// ✅ — read live from ViewModel by ID
class PostCard extends StatelessWidget {
  final String postId;
  const PostCard({required this.postId});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedViewModel>();
    final isLiked = vm.isLiked(postId);
    final likeCount = vm.likeCount(postId);
    ...
  }
}
```

### Use ListView.builder — never ListView with children

```dart
// ❌ — renders all items upfront
ListView(children: posts.map((p) => PostCard(postId: p.id)).toList())

// ✅
ListView.builder(
  itemCount: posts.length,
  itemBuilder: (context, i) => PostCard(postId: posts[i].id),
)
```

---

## 12. Navigation

### Named routes only — never push widget classes

```dart
// ❌
Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen()));

// ✅
Navigator.pushNamed(context, AppRoutes.profile, arguments: userId);
```

### Pass IDs through routes — never full objects

```dart
// ❌ — serialisation issues, stale data
Navigator.pushNamed(context, AppRoutes.profile, arguments: userObject);

// ✅
Navigator.pushNamed(context, AppRoutes.profile, arguments: userId);
```

---

## 13. Images

### Always use CachedNetworkImage with a fallback

```dart
// ❌
Image.network(avatarUrl)

// ✅
CachedNetworkImage(
  imageUrl: avatarUrl,
  placeholder: (context, url) => const AvatarShimmer(),
  errorWidget: (context, url, error) => const DefaultAvatar(),
)
```

---

## 14. Forms

### Always validate with Form + GlobalKey before submitting

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: TextFormField(
    validator: (value) {
      if (value == null || value.trim().isEmpty) return AppStrings.fieldRequired;
      return null;
    },
  ),
)

ElevatedButton(
  onPressed: () {
    if (_formKey.currentState!.validate()) {
      vm.submit(controller.text.trim()); // always trim
    }
  },
  child: const Text("Save"),
)
```

---

## 15. ViewModel Lifecycle

Every ViewModel that owns state must implement reset() and call it from dispose().

```dart
class FeedViewModel extends ChangeNotifier {
  bool _disposed = false;
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  void reset() {
    _posts = [];
    _isLoading = false;
    _errorMessage = null;
  }

  @override
  void dispose() {
    reset();
    _disposed = true;
    super.dispose();
  }
}
```

---

## 16. Architecture — What Goes Where

| Layer      | Folder          | Allowed                                           | Never                                                                        |
| ---------- | --------------- | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| Screen     | `screens/`      | Read ViewModel, call ViewModel methods, render UI | Business logic, API calls, Supabase, `setState` if ViewModel owns that state |
| ViewModel  | `viewmodels/`   | Call repository, call `notifyListeners()`         | `BuildContext`, Supabase, HTTP, `import flutter/material.dart`               |
| Repository | `repositories/` | Supabase, API calls, Isar read/write              | Business logic, UI logic                                                     |
| Model      | `models/`       | Data shape, `fromJson`, `toJson`, `copyWith`      | Logic of any kind                                                            |

---

## 17. Pre-Commit Checklist

Run all of these before every commit. All must pass.

```bash
# 1. Format
dart format lib/ --set-exit-if-changed

# 2. Analyse
flutter analyze

# 3. Debug prints
grep -rn "print\|debugPrint" lib/ --include="*.dart"

# 4. Hardcoded colors
grep -rn "Colors\.\|Color(0x" lib/ --include="*.dart"

# 5. Raw strings (spot check)
grep -rn 'Text("' lib/features/ --include="*.dart"

# 6. Unresolved markers
grep -rn "TODO\|FIXME\|HACK" lib/ --include="*.dart"

# 7. Tests
flutter test
```

Steps 3–6 must return no output. Steps 1, 2, and 7 must exit with code 0.

---

## 18. Things Claude Code Must Never Do

- Put business logic, API calls, or Supabase calls in a screen or widget
- Use `setState` in a screen that has a ViewModel
- Call `notifyListeners()` without replacing collection references
- Use `context.watch` inside a callback
- Use `Color(0x...)` or `Colors.*` directly — always use `AppColors`
- Put raw strings in `Text()` — always use `AppStrings`
- Fetch all rows without pagination
- Add a scroll listener without `isLoadingMore` and `hasMore` guards
- Leave a stream subscription, Timer, or AnimationController without `dispose()`
- Store auth tokens or sensitive data in SharedPreferences
- Use the Supabase service role key in Flutter
- Pass mutable state (isLiked, likeCount, etc.) as widget constructor props
- Use `Image.network` — always use `CachedNetworkImage`
- Use `Navigator.push` with a widget class — always use named routes
- Push a full object through a route argument — always push an ID
- Use `ListView` with a `children` array for dynamic data
- Apply optimistic UI to destructive, irreversible, or server-computed actions
- Leave any async method without a `mounted` check before using `context` afterward
- Swallow exceptions with an empty catch block
- Build a screen without all four states: loading, error, empty, content
