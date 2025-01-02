import whisper
import pandas as pd
import wave
import numpy as np
import whisper
import tempfile
import os
import librosa

model = whisper.load_model("small")
options = {"language": "en"}

loc = "C:\\Users\\86135\\"
dir = "Box\\CoganLab\\ECoG_Task_Data\\response_coding\\response_coding_results\\LexicalDecRepDelay\\"
# subjs = ["D23","D24","D25","D26","D27","D28",'D29','D32','D35','D38','D42','D44','D47']
subjs =['D47']

def read_audio(wav_path):
    audio_data, frame_rate=librosa.load(wav_path,sr=None)
    return audio_data, frame_rate

def extract_segment(audio_data, frame_rate, start_time, end_time):
    start_frame = int(start_time * frame_rate)
    end_frame = int(end_time * frame_rate)
    return audio_data[start_frame:end_frame]

def save_temp_wav(audio_segment, frame_rate, temp_wav_path):
    with wave.open(temp_wav_path, 'wb') as wav_file:
        wav_file.setnchannels(1) 
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(frame_rate)
        wav_file.writeframes(audio_segment.tobytes())

def process_audio_segments(audio_data, frame_rate, time_windows):
    results = []
    for _, row in time_windows.iterrows():

        start_time = row[0]
        print(start_time)
        end_time = row[1]
        audio_segment = extract_segment(audio_data, frame_rate, start_time, end_time)

        with tempfile.NamedTemporaryFile(delete=False, suffix='.wav') as temp_file:
            temp_wav_path = temp_file.name

        save_temp_wav(audio_segment, frame_rate, temp_wav_path)
        
        result = model.transcribe(temp_wav_path, fp16=False, **options)
        text = result['text']
        print(text)

        os.remove(temp_wav_path)
        
        results.append([start_time, end_time, text])
    return results

def main():

    for subj in subjs:

        txt_path1 = loc + dir + subj + "\\mfa\\annotated_yes_windows.txt"
        time_windows1 = pd.read_csv(txt_path1, sep='\t',header=None)

        txt_path2 = loc + dir + subj + "\\mfa\\annotated_resp_windows.txt"
        time_windows2 = pd.read_csv(txt_path2, sep='\t',header=None)

        time_windows = pd.concat([time_windows1, time_windows2], axis=0, ignore_index=True)

        time_windows = time_windows.sort_values(by=0)

        wav_path = loc + dir + subj + "\\allblocks.wav"
        audio_data, frame_rate = read_audio(wav_path)

        results = process_audio_segments(audio_data, frame_rate, time_windows)
        
        output_df = pd.DataFrame(results)
        output_df.to_csv(loc + dir + subj + "\\mfa\\mfa_whisper_rscode.txt", sep='\t', header=False, index=False)

if __name__ == "__main__":
    main()
