import cv2
import pandas as pd
import numpy as np
import os
from moviepy.editor import VideoFileClip, concatenate_videoclips

def extract_volleyball_ultra_sensitive(video_path, output_video, output_csv):
    print("KROK 1: Analiza wysokiej czułości (Raw Motion Detection)...")
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    motion_data = []
    ret, prev_frame = cap.read()
    
    # --- DEFINE ROI (Region of Interest) ---
    # Wycinamy górę (sufit) i dół (kibice/ławki), zostawiamy środek gdzie jest boisko
    # To drastycznie poprawia wykrywanie małych ruchów piłki
    roi_top = int(height * 0.15)
    roi_bottom = int(height * 0.85)

    prev_gray = cv2.cvtColor(prev_frame[roi_top:roi_bottom, :], cv2.COLOR_BGR2GRAY)
    prev_gray = cv2.GaussianBlur(prev_gray, (15, 15), 0)
    
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret: break
            
        # Analizujemy tylko obszar boiska
        roi_frame = frame[roi_top:roi_bottom, :]
        gray = cv2.cvtColor(roi_frame, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (15, 15), 0)
        
        # Bardzo niski próg różnicy (15), żeby złapać piłkę na jasnym tle
        diff = cv2.absdiff(prev_gray, gray)
        _, thresh = cv2.threshold(diff, 15, 255, cv2.THRESH_BINARY)
        
        # Liczymy po prostu ilość ruchu (procent klatki)
        motion_count = np.sum(thresh) / 255
        motion_data.append(motion_count)
        
        prev_gray = gray
        frame_count += 1
        if frame_count % 1000 == 0:
            print(f" Analiza: {frame_count} klatek...")

    cap.release()

    print("KROK 2: Algorytm progu adaptacyjnego...")
    series = pd.Series(motion_data)
    
    # Bardzo krótkie wygładzanie (0.5s), żeby nie zgubić szybkich akcji (serw w siatkę)
    smoothed = series.rolling(window=int(fps*0.5), center=True).mean().fillna(0)
    
    # Próg ustawiony na poziomie średniej + mały margines. 
    # To jest znacznie czulsze niż 85. percentyl.
    threshold = smoothed.mean() * 1.2 
    is_action = smoothed > threshold
    
    actions = []
    in_action = False
    start_f = 0
    
    for i, val in enumerate(is_action):
        if val and not in_action:
            start_f = i
            in_action = True
        elif not val and in_action:
            end_f = i
            in_action = False
            # Akceptujemy nawet krótkie akcje (min 1.5 sekundy), żeby złapać błędy serwisu
            if (end_f - start_f) > (fps * 1.5):
                actions.append((start_f, end_f))

    # --- PADDING I ŁĄCZENIE ---
    # Bardzo duży padding z przodu (6 sekund), żeby na pewno złapać kozłowanie piłki przed serwem
    final_periods = []
    for s, e in actions:
        start_s = max(0, (s / fps) - 6.0) 
        end_s = (e / fps) + 1.5 # zostawiamy 1.5s na reakcję sędziego
        final_periods.append({"Poczatek_s": round(start_s, 2), "Koniec_s": round(end_s, 2)})

    # Łączymy fragmenty, jeśli przerwa między nimi jest mniejsza niż 4 sekundy
    # (To uratuje akcje, gdzie piłka leci wysoko i ruch na moment zamiera)
    merged = []
    if final_periods:
        curr = final_periods[0]
        for next_p in final_periods[1:]:
            if next_p['Poczatek_s'] < curr['Koniec_s'] + 4.0:
                curr['Koniec_s'] = max(curr['Koniec_s'], next_p['Koniec_s'])
            else:
                merged.append(curr)
                curr = next_p
        merged.append(curr)

    # Zapis CSV
    df = pd.DataFrame(merged)
    df.to_csv(output_csv, index=False)
    
    # KROK 3: Generowanie Wideo
    print(f" Wykryto {len(merged)} potencjalnych akcji. Renderowanie...")
    try:
        with VideoFileClip(video_path) as video:
            clips = [video.subclip(m['Poczatek_s'], min(m['Koniec_s'], video.duration)) for m in merged]
            if clips:
                final_video = concatenate_videoclips(clips)
                final_video.write_videofile(output_video, codec="libx264", audio_codec="aac", fps=fps)
                final_video.close()
                for c in clips: c.close()
    except Exception as e:
        print(f"Błąd renderowania: {e}")

if __name__ == "__main__":
    INPUT = "ATJSW_Volley_Concept_Katowice_MlodzikSet2_VID20260110123022.mp4"
    extract_volleyball_ultra_sensitive(INPUT, "akcje_v4_czule.mp4", "rozpiska_v4.csv")