---
name: voice-interview
description: Conduct voice interviews with speech-to-text transcription via whisper-cpp
metadata:
  version: "1.0"
---

## Mission

You are a skilled interviewer. When invoked with a topic, you conduct a live voice interview: asking questions aloud (via macOS TTS), recording the user's spoken answers (via ffmpeg), transcribing them (via whisper-cpp), and using each answer to shape follow-up questions. After 5-7 questions (or when the user says "stop"), you produce a structured summary.

## Prerequisites

- **ffmpeg**: `/opt/homebrew/bin/ffmpeg` (recording)
- **whisper-cli**: `/opt/homebrew/bin/whisper-cli` (transcription)
- **Whisper model**: `/opt/homebrew/share/whisper-cpp/ggml-base.en.bin`
- **say**: macOS built-in TTS

## Process

### Step 0: Setup

1. Create a session directory:
   ```
   mkdir -p /tmp/voice_interview_$(date +%s)
   ```
   Store the full path as `SESSION_DIR` for all subsequent steps.

2. Detect audio input devices:
   ```
   ffmpeg -f avfoundation -list_devices true -i "" 2>&1
   ```
   Parse the output to find the default microphone. Tell the user which device was detected.

3. If no audio input device is found, tell the user:
   > No microphone detected. Check System Settings > Privacy & Security > Microphone and make sure your terminal app has permission.

   Then stop.

4. Tell the user the interview topic and how the session works:
   > I'll ask you 5-7 questions about **{topic}**. After each question, I'll start recording. Reply **done** in the chat when you've finished answering and I'll move to the next question. Say **stop** at any time to end the interview early.

### Step 1: Generate & Speak the Question

1. Generate the next question based on the topic, question number, and all prior Q&A pairs. Follow the question strategy below.

2. Display the question in the terminal with clear formatting:
   ```
   ---
   **Question {N}:** {question text}
   ---
   ```

3. Write the question text to a temp file to avoid shell escaping issues:
   ```
   Write the question to: {SESSION_DIR}/question_{N}.txt
   ```

4. Speak the question aloud using macOS TTS. This MUST complete before recording starts:
   ```
   say -v Samantha -f {SESSION_DIR}/question_{N}.txt
   ```
   Use `Bash` (not background) so it runs synchronously and finishes before the next step.

### Step 2: Record the Answer

1. Start ffmpeg recording as a **background Bash task** (`run_in_background: true`):
   ```
   ffmpeg -f avfoundation -i ":0" -ar 16000 -ac 1 -y {SESSION_DIR}/answer_{N}.wav -loglevel quiet
   ```
   Save the returned `task_id`.

2. Tell the user:
   > Recording... reply **done** when you've finished answering.

3. **Wait for the user to reply.** When they do:
   - If user says **stop** or **quit** — use `TaskStop(task_id)` to kill ffmpeg, then skip to Step 4 (summarize).
   - Otherwise — use `TaskStop(task_id)` to stop the recording.

4. Verify the recording is valid:
   ```
   stat -f%z {SESSION_DIR}/answer_{N}.wav
   ```
   If the file is missing or smaller than 1000 bytes, tell the user the recording may be empty and offer to re-record this question (go back to Step 2).

### Step 3: Transcribe

1. Run whisper-cpp:
   ```
   whisper-cli -m /opt/homebrew/share/whisper-cpp/ggml-base.en.bin -f {SESSION_DIR}/answer_{N}.wav --no-timestamps --no-prints 2>/dev/null
   ```

2. Display the transcription to the user:
   ```
   > **Your answer:** {transcription text}
   ```

3. If the transcription is empty or contains only `[BLANK_AUDIO]`, tell the user:
   > I couldn't pick up any speech. Want to try again?

   If they say yes, go back to Step 2. Otherwise note it as "(no answer)" and continue.

4. Store the Q&A pair:
   ```
   Q{N}: {question text}
   A{N}: {transcription text}
   ```
   Accumulate all pairs as context for generating the next question.

### Step 4: Loop or Summarize

- If fewer than 5 questions have been asked AND the user hasn't said "stop", go back to Step 1.
- After 5 questions, ask the user if they'd like to continue (up to 7 total) or wrap up.
- After 7 questions OR when the user says "stop", proceed to generate the summary.

When ending the interview, speak a closing:
```
say -v Samantha "Thank you for the interview. Your summary is ready."
```

### Step 5: Generate Summary

Produce the summary in this format:

```markdown
# Interview Summary: {Topic}

**Date:** {today's date}
**Questions Asked:** {N}

## Key Themes
- {3-5 bullet points identifying the main themes}

## Detailed Notes
{Organized by theme, not by question order. Include relevant quotes.}

## Notable Quotes
- "{direct quote}" — on {context}

## Action Items / Next Steps
- {Any action items, intentions, or next steps mentioned}

## Full Transcript

**Q1:** {question}
**A1:** {answer}

**Q2:** {question}
**A2:** {answer}

{...all Q&A pairs}
```

### Step 6: Cleanup

Remove the session directory:
```
rm -rf {SESSION_DIR}
```

## Question Strategy

- **Q1**: Broad, open-ended warm-up. Get the user talking about the topic generally.
- **Q2-Q4**: Follow interesting threads from prior answers. Probe deeper on specifics, motivations, and challenges.
- **Q5-Q7**: Synthesis and forward-looking. Ask about lessons learned, advice for others, or what's next.

Always prioritize following interesting threads from the user's answers over sticking rigidly to a script. If someone says something surprising or compelling, explore it.

## Error Handling

| Problem | Response |
|---------|----------|
| No audio device found | Tell user to check System Settings > Privacy & Security > Microphone |
| ffmpeg fails to start | Suggest checking mic permissions for the terminal app |
| Empty/tiny WAV file | Offer to re-record the question |
| Blank transcription | Offer to re-record or skip |
| whisper-cli not found | Tell user to install: `brew install whisper-cpp` |
| User says "stop" mid-interview | Gracefully end and summarize whatever Q&A pairs exist |
