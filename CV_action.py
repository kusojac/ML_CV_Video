import cv2
import pandas as pd
import numpy as np
from moviepy.editor import VideoFileClip, concatenate_videoclips

def extract_volleyball_actions(video_path, output_video, output_csv):
    print("KROK 1: Rozpoczynam analizę wideo (detekcja energii ruchu)...")
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    
    motion_scores = []
    
    ret, prev_frame = cap.read()
    if not ret:
        print("Błąd odczytu wideo. Sprawdź ścieżkę do pliku.")
        return
        
    # Konwersja do skali szarości i rozmycie (redukcja szumu)
    prev_gray = cv2.cvtColor(prev_frame, cv2.COLOR_BGR2GRAY)
    prev_gray = cv2.GaussianBlur(prev_gray, (21, 21), 0)
    
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        # Opcjonalnie: Wykluczenie trybun (ROI). 
        # Odkomentuj poniższą linię, aby ignorować dolne 20% ekranu:
        # frame = frame[:int(frame.shape[0]*0.8), :] 
            
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (21, 21), 0)
        
        # Obliczenie różnicy między klatką obecną a poprzednią
        frame_diff = cv2.absdiff(prev_gray, gray)
        _, thresh = cv2.threshold(frame_diff, 25, 255, cv2.THRESH_BINARY)
        
        # Suma białych pikseli (intensywność ruchu)
        motion_score = np.sum(thresh) / 255
        motion_scores.append(motion_score)
        
        prev_gray = gray
        frame_count += 1
        if frame_count % 1000 == 0:
            print(f" Przeanalizowano {frame_count}/{total_frames} klatek...")

    cap.release()
    
    print("KROK 2: Przetwarzanie danych i szukanie akcji...")
    
    # 1. Wygładzenie sygnału (okno 1.5 sekundy - ZMIENIONE)
    window_size = int(fps * 1.5)
    smoothed_scores = pd.Series(motion_scores).rolling(window=window_size, center=True).mean().fillna(0)
    
    # 2. Ustalenie progu (Threshold - ZMIENIONE na 0.5)
    threshold = smoothed_scores.mean() + 0.5 * smoothed_scores.std()
    is_action = smoothed_scores > threshold
    
    # 3. Wyciąganie przedziałów czasowych
    actions = []
    in_action = False
    start_frame = 0
    
    for i, val in enumerate(is_action):
        if val and not in_action:
            start_frame = i
            in_action = True
        elif not val and in_action:
            end_frame = i
            in_action = False
            # Zapisujemy tylko akcje trwające dłużej niż 3 sekundy
            if (end_frame - start_frame) > (fps * 3):
                actions.append((start_frame, end_frame))
                
    if in_action: 
        actions.append((start_frame, len(is_action)))
        
    # 4. Dodanie asymetrycznego marginesu (Padding - ZMIENIONE)
    padding_sec_przed = 4.0 # 4 sekundy przed wykryciem ruchu (żeby złapać serw)
    padding_sec_po = 1.0    # 1 sekunda po opadnięciu emocji (odcięcie zmiany pozycji)
    
    timestamps = []
    for start_f, end_f in actions:
        start_sec = max(0, (start_f / fps) - padding_sec_przed)
        end_sec = (end_f / fps) + padding_sec_po
        timestamps.append({"Poczatek_s": round(start_sec, 2), "Koniec_s": round(end_sec, 2)})
        
    # Łączenie akcji, jeśli przerwa między nimi jest krótsza niż 3 sekundy
    merged = []
    for t in timestamps:
        if not merged:
            merged.append(t)
        else:
            last = merged[-1]
            if t['Poczatek_s'] <= last['Koniec_s'] + 3.0:
                last['Koniec_s'] = max(last['Koniec_s'], t['Koniec_s'])
            else:
                merged.append(t)
                
    # 5. Zapis do CSV
    print(f" Znaleziono {len(merged)} wymian! Zapisuję do pliku {output_csv}...")
    df = pd.DataFrame(merged)
    df.to_csv(output_csv, index=False)
    
    # 6. Tworzenie wideo wynikowego
    print(f"KROK 3: Wycinanie klipów i generowanie pliku {output_video}. To może chwilę potrwać...")
    video = VideoFileClip(video_path)
    clips = []
    for t in merged:
        start = t['Poczatek_s']
        end = min(t['Koniec_s'], video.duration)
        clips.append(video.subclip(start, end))
        
    final_video = concatenate_videoclips(clips)
    final_video.write_videofile(output_video, codec="libx264", audio_codec="aac")
    print(" GOTOWE! ")

# === URUCHOMIENIE SKRYPTU ===
if __name__ == "__main__":
    # Używamy pliku, który został przez Ciebie wgrany
    nazwa_pliku_wejsciowego = "ATJSW_Volley_Concept_Katowice_MlodzikSet2_VID20260110123022.mp4" 
    plik_wyjsciowy_wideo = "tylko_akcje_v2.mp4"
    plik_wyjsciowy_csv = "rozpiska_akcji_v2.csv"
    
    extract_volleyball_actions(nazwa_pliku_wejsciowego, plik_wyjsciowy_wideo, plik_wyjsciowy_csv)