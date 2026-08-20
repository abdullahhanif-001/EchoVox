# whisper.cpp Production Patches

EchoVox applies five targeted patches to [whisper.cpp/src/whisper.cpp](../../whisper.cpp/src/whisper.cpp) for production Urdu/Punjabi deployment.

## Patch 1: Short Audio Auto-Padding

**Problem:** Utterances under 1.5 seconds are silently skipped or return empty strings.

**Fix:** Auto-pad short audio with zeros to minimum 1.5 seconds before mel conversion.

**Location:** Lines 6845-6854

```cpp
if (n_samples > 0 && n_samples < min_samples) {
    state->short_pad_buf.resize(min_samples, 0.0f);
    std::copy(samples, samples + n_samples, state->short_pad_buf.begin());
    std::fill(state->short_pad_buf.begin() + n_samples, state->short_pad_buf.end(), 0.0f);
    samples = state->short_pad_buf.data();
    n_samples = min_samples;
}
```

**Verified by:** Mythos zero-drop assertion, Ultra-Heavy Patch 1 test.

## Patch 2: Tail Truncation Fix

**Problem:** Final 1-2 words dropped at end of streaming transcription.

**Fix:** Relax `delta_min` duration requirement for the final audio chunk.

**Location:** Line 6898

```cpp
const int delta_min = (seek_end > 0 && seek_end < seek_start + 20) ? 1 : 10;
```

**Verified by:** Streaming integration tests in deployment scripts.

## Patch 3: Memory Pre-Allocation (Mel Buffer)

**Problem:** Per-call `samples_padded` vector allocation causes RAM spikes during continuous streaming.

**Fix:** Reuse persistent `mel_pad_buf` from whisper state.

**Location:** Line 3203

```cpp
auto & samples_padded = wstate.mel_pad_buf;
```

**Verified by:** Ultra-Heavy memory drift assertion (0.237% over 50K steps).

## Patch 4: Trigram Repetition Kill Switch

**Problem:** Infinite hallucination loops ("Thank you for watching" repeating).

**Fix:** Detect when the same 3-token sequence repeats three times consecutively and force End-Of-Text.

**Location:** Lines 7453-7468

```cpp
// trigram repetition kill switch
if (tokens.size() >= 9) {
    bool trigram_repeat = true;
    for (int k = 0; k < 3 && trigram_repeat; k++) {
        if (tokens[tokens.size()-1-k] != tokens[tokens.size()-4-k] ||
            tokens[tokens.size()-1-k] != tokens[tokens.size()-7-k]) {
            trigram_repeat = false;
        }
    }
    if (trigram_repeat) {
        // force EOT token
    }
}
```

**Verified by:** Ultra-Heavy trigram kill assertion (stops at exactly 9 tokens).

## Patch 5: Pre-Allocated State Buffers

**Problem:** Repeated buffer allocations in whisper_state during streaming.

**Fix:** Add persistent buffers to whisper_state struct.

**Location:** Lines 937-938

```cpp
std::vector<float> short_pad_buf;
std::vector<float> mel_pad_buf;
```

**Verified by:** Ultra-Heavy memory pre-allocation assertion.

## Production Parameters

Recommended server flags (see [deploy-vps.sh](../../deploy-vps.sh)):

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `--no-speech-thold` | 0.4 | Lower threshold for low-energy Urdu speech |
| `--beam-size` | 5 | Balance accuracy vs latency |
| `--vad-min-speech-duration-ms` | 200 | Detect short affirmatives |
| `--vad-speech-pad-ms` | 400 | Prevent word clipping |
