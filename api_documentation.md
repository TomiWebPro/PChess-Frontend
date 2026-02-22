# PChess API Documentation for Frontend Developers

## Overview

This document provides documentation for the PChess API endpoints that are relevant for frontend development. The API provides access to application settings, available models, and chess puzzle data.

## Base URL

The API runs on a configurable port (default: 8787).

```
http://localhost:<port>
```

## API Endpoints

### 1. Settings Management

#### Get Settings
Retrieve all user settings that are relevant for the frontend.

**Endpoint:** `GET /settings`

**Response:**
```json
{
  "user_elo": 800,
  "max_evaluation_strength": 15,
  "show_boarder": 1,
  "piece_set": "default",
  "board_theme": "blue",
  "piece_shift_method": "drag",
  "API_key": "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",
  "user_locale": "en",
  "model": "openai/gpt-5-chat",
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| user_elo | INTEGER | User's Elo rating |
| max_evaluation_strength | INTEGER | Stockfish's hard limit for evaluation lines |
| show_boarder | INTEGER | Flag to show boarder (0 or 1) |
| piece_set | TEXT | Selected piece set |
| board_theme | TEXT | Selected board theme |
| piece_shift_method | TEXT | Method for piece movement |
| API_key | TEXT | User's API key for external services |
| user_locale | TEXT | User's locale setting |
| model | TEXT | Selected AI model |

#### Update Settings
Update user settings from the frontend.

**Endpoint:** `POST /settings`

**Request Body:**
```json
{
  "user_elo": 1200,
  "max_evaluation_strength": 2000,
  "show_boarder": 0,
  "piece_set": "modern",
  "board_theme": "green",
  "piece_shift_method": "click",
  "API_key": "new-api-key-here",
  "user_locale": "fr",
  "model": "openai/gpt-4",
}
```

**Request Fields:**
Any combination of the fields listed in the response section above. Only specified fields will be updated.

**Response:**
```json
{
  "message": "Settings updated successfully"
}
```

### 2. Model Management

#### Get Available OpenRouter Models
Retrieve a list of all available OpenRouter model IDs that can be selected by users.

**Endpoint:** `GET /openrouter/models`

**Response:**
```json
{
  "model_ids": [
    "openai/gpt-5-chat",
    "anthropic/claude-3.5-sonnet",
    "google/gemini-pro"
  ]
}
```

### 3. Chess Puzzle Data

#### Get Available FEN IDs
Retrieve a list of all available chess puzzle IDs.

**Endpoint:** `GET /available/ids`

**Response:**
```json
[1, 2, 4, 5, 6, 8, 12, 33]
```

The response is an array containing the IDs of all available chess puzzles in the database. These IDs can be used with other puzzle-related functions to retrieve specific puzzles.

### 4. FEN State Retrieval

#### Get FEN State by ID
Retrieve the FEN state, last move, and user color for a specific puzzle ID.

**Endpoint:** `GET /fen/{id}`

**Path Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| id | INTEGER | The ID of the puzzle to retrieve |

**Response:**
```json
{
  "fen": "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3",
  "last_move": "g1f3",
  "user_color": 0
}
```

**Response Fields:**
| Field | Type | Description |
|-------|------|-------------|
| fen | TEXT | The puzzle position in FEN notation |
| last_move | TEXT | The last move of the puzzle in algebraic notation (e.g., "e2e4") |
| user_color | INTEGER | The user's playing color (0 for white, 1 for black) |

### 5. AI Response

#### Get AI Response for User Move
Request an AI response for a specific puzzle and user move. The backend will return the OpenRouter API request format, which the frontend should then use to make the actual request to OpenRouter.

**Endpoint:** `POST /ai-response`

**Request Body:**
```json
{
  "puzzle_id": 1,
  "user_move": "e2e4"
}
```

**Request Fields:**
| Field | Type | Description |
|-------|------|-------------|
| puzzle_id | INTEGER | The ID of the puzzle |
| user_move | TEXT | The user's move in algebraic notation (e.g., "e2e4") |

**Response:**
```json
{
  "model": "openai/gpt-5-chat",
  "messages": [
    {
      "role": "user",
      "content": "Backend generated prompt based on puzzle_id and user_move"
    }
  ],
  "stream": true
}
```
The response is a JSON object containing the OpenRouter API request payload. The frontend should use this payload to make a POST request to `https://openrouter.ai/api/v1/chat/completions` with the appropriate Authorization header.

