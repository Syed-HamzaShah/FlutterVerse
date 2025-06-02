import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe Neon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        primaryColor: Colors.deepPurpleAccent,
        textTheme: TextTheme(
          headlineMedium: TextStyle(
            fontFamily: 'ComicSansMS',
            fontWeight: FontWeight.bold,
            color: Colors.deepPurpleAccent,
            letterSpacing: 1.2,
          ),
          labelLarge: TextStyle(
            fontFamily: 'ComicSansMS',
            fontSize: 20,
            color: Colors.deepPurpleAccent,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(color: Colors.grey[300]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: TextStyle(
              fontFamily: 'ComicSansMS',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            shadowColor: Colors.deepPurpleAccent.withOpacity(0.8),
            elevation: 8,
          ),
        ),
      ),
      home: ModeSelectionScreen(),
    );
  }
}

enum Player { X, O, None }

enum GameMode { SinglePlayer, Multiplayer }

enum Difficulty { Easy, Medium, Hard }

/// Screen 1: Select game mode
class ModeSelectionScreen extends StatelessWidget {
  void _goToDifficultyScreen(BuildContext context) {
    Navigator.push(context, _createRoute(DifficultySelectionScreen()));
  }

  void _goToGameScreen(
    BuildContext context,
    GameMode mode,
    Difficulty? difficulty,
  ) {
    Navigator.pushReplacement(
      context,
      _createRoute(GameScreen(mode: mode, difficulty: difficulty)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium;
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Tic Tac Toe", style: style?.copyWith(fontSize: 48)),
              SizedBox(height: 32),
              ElevatedButton.icon(
                icon: Icon(Icons.person_outline, size: 28),
                label: Text("Single Player"),
                onPressed: () => _goToDifficultyScreen(context),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.people_outline, size: 28),
                label: Text("Multiplayer"),
                onPressed: () =>
                    _goToGameScreen(context, GameMode.Multiplayer, null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 2: Select difficulty (for single player only)
class DifficultySelectionScreen extends StatelessWidget {
  void _goToGameScreen(BuildContext context, Difficulty difficulty) {
    Navigator.pushReplacement(
      context,
      _createRoute(
        GameScreen(mode: GameMode.SinglePlayer, difficulty: difficulty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineMedium;
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Difficulty'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Choose your challenge",
                style: style?.copyWith(fontSize: 32),
              ),
              SizedBox(height: 40),
              ...Difficulty.values.map((diff) {
                String label = diff.toString().split('.').last;
                Color color = diff == Difficulty.Easy
                    ? Colors.greenAccent
                    : diff == Difficulty.Medium
                    ? Colors.amberAccent
                    : Colors.redAccent;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.8),
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 12,
                    ),
                    onPressed: () => _goToGameScreen(context, diff),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 3: The Game itself
class GameScreen extends StatefulWidget {
  final GameMode mode;
  final Difficulty? difficulty;
  const GameScreen({required this.mode, this.difficulty});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  List<Player> board = List.filled(9, Player.None);
  Player currentPlayer = Player.X;
  bool gameOver = false;
  String message = "";

  int xScore = 0;
  int oScore = 0;
  int draws = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // If single player and AI starts second player O
    if (widget.mode == GameMode.SinglePlayer && currentPlayer == Player.O) {
      Future.delayed(Duration(milliseconds: 500), aiMove);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void resetGame() {
    setState(() {
      board = List.filled(9, Player.None);
      currentPlayer = Player.X;
      gameOver = false;
      message = "";
    });
  }

  bool checkWinner(Player player) {
    const winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var pattern in winPatterns) {
      if (pattern.every((index) => board[index] == player)) {
        return true;
      }
    }
    return false;
  }

  bool get isDraw => !board.contains(Player.None);

  void handleTap(int index) {
    if (board[index] != Player.None || gameOver) return;

    setState(() {
      board[index] = currentPlayer;

      if (checkWinner(currentPlayer)) {
        gameOver = true;
        if (currentPlayer == Player.X)
          xScore++;
        else
          oScore++;
        message = "${playerToString(currentPlayer)} Wins! 🎉";
      } else if (isDraw) {
        gameOver = true;
        draws++;
        message = "It's a Draw! 🤝";
      } else {
        currentPlayer = (currentPlayer == Player.X) ? Player.O : Player.X;
        message = "Current Turn: ${playerToString(currentPlayer)}";

        if (widget.mode == GameMode.SinglePlayer && currentPlayer == Player.O) {
          Future.delayed(Duration(milliseconds: 600), aiMove);
        }
      }
    });
  }

  String playerToString(Player p) {
    switch (p) {
      case Player.X:
        return 'X';
      case Player.O:
        return 'O';
      case Player.None:
        return '';
    }
  }

  Color playerColor(Player p) {
    switch (p) {
      case Player.X:
        return Colors.deepPurpleAccent;
      case Player.O:
        return Colors.amberAccent;
      default:
        return Colors.grey.shade800;
    }
  }

  void aiMove() {
    int move;
    switch (widget.difficulty) {
      case Difficulty.Easy:
        move = getRandomMove();
        break;
      case Difficulty.Medium:
        move = Random().nextBool() ? getRandomMove() : getBestMove();
        break;
      case Difficulty.Hard:
      default:
        move = getBestMove();
        break;
    }
    handleTap(move);
  }

  int getRandomMove() {
    List<int> empty = [];
    for (int i = 0; i < board.length; i++) {
      if (board[i] == Player.None) empty.add(i);
    }
    return empty[Random().nextInt(empty.length)];
  }

  int getBestMove() {
    int bestScore = -1000;
    int bestMove = -1;

    for (int i = 0; i < 9; i++) {
      if (board[i] == Player.None) {
        board[i] = Player.O;
        int score = minimax(board, false);
        board[i] = Player.None;
        if (score > bestScore) {
          bestScore = score;
          bestMove = i;
        }
      }
    }
    return bestMove;
  }

  int minimax(List<Player> b, bool isMaximizing) {
    if (checkWinner(Player.O)) return 1;
    if (checkWinner(Player.X)) return -1;
    if (!b.contains(Player.None)) return 0;

    if (isMaximizing) {
      int bestScore = -1000;
      for (int i = 0; i < 9; i++) {
        if (b[i] == Player.None) {
          b[i] = Player.O;
          int score = minimax(b, false);
          b[i] = Player.None;
          bestScore = max(score, bestScore);
        }
      }
      return bestScore;
    } else {
      int bestScore = 1000;
      for (int i = 0; i < 9; i++) {
        if (b[i] == Player.None) {
          b[i] = Player.X;
          int score = minimax(b, true);
          b[i] = Player.None;
          bestScore = min(score, bestScore);
        }
      }
      return bestScore;
    }
  }

  Widget buildCell(int index) {
    Player p = board[index];
    return GestureDetector(
      onTap: () {
        if (widget.mode == GameMode.Multiplayer || currentPlayer == Player.X) {
          handleTap(index);
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        decoration: BoxDecoration(
          color: p == Player.None
              ? Colors.grey.shade900
              : playerColor(p).withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: p != Player.None
              ? [
                  BoxShadow(
                    color: playerColor(p).withOpacity(0.8),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            playerToString(p),
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 12,
                  color: p != Player.None
                      ? playerColor(p).withOpacity(0.9)
                      : Colors.transparent,
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildScoreBoard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        ScoreWidget(
          label: "X Wins",
          score: xScore,
          color: Colors.deepPurpleAccent,
        ),
        ScoreWidget(label: "Draws", score: draws, color: Colors.grey),
        ScoreWidget(label: "O Wins", score: oScore, color: Colors.amberAccent),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double gridSize = MediaQuery.of(context).size.width * 0.9;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tic Tac Toe",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, size: 28),
            tooltip: "Restart Game",
            onPressed: resetGame,
          ),
          IconButton(
            icon: Icon(Icons.home_outlined, size: 28),
            tooltip: "Back to menu",
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                _createRoute(ModeSelectionScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            buildScoreBoard(),
            SizedBox(height: 20),
            Text(
              gameOver
                  ? message
                  : "Current Turn: ${playerToString(currentPlayer)}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: gameOver ? Colors.redAccent : playerColor(currentPlayer),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Container(
                width: gridSize,
                height: gridSize,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurpleAccent.withOpacity(0.4),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: GridView.builder(
                  itemCount: 9,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) {
                    return buildCell(index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreWidget extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const ScoreWidget({
    required this.label,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

Route _createRoute(Widget screen) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}
