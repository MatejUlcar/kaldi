import re
import sys


task = sys.argv[1] #train ali test
trsfilename = sys.argv[2]

trspath = 'local/raw_data/gos2/Spoken corpus Gos VideoLectures 2.0 (transcription)/GosVL.TRS/' #folder with transcription
pd_path = 'local/data_prepare' #prepared data folder
wav_path = 'local/raw_data/gos2/GosVL.wav/' #folder with audio files
#kaldi_path = '/opt/kaldi/egs/slovenscina/slovenscina_audio/'

#trsfilename = 'GosVL01_pravo_s3.trs' #SAMO TO VRSTICO SPREMINJAS (upam)
trsfilename2 = re.search('(.+?)_s3.trs', trsfilename)
trsfilename2 = trsfilename2.group(1)+'_s2.trs'

wavfilename = re.search('(.+?)_s[23].trs', trsfilename)
recording_id = wavfilename.group(1)
wavfilename = recording_id+'.wav'

idfilename = re.search('(.+?)s[23].trs', trsfilename)
idfilename1 = idfilename.group(1)+'g1.txt'
idfilename2 = idfilename.group(1)+'g2.txt'

spkrs = {}
f = open(trspath+trsfilename, 'r')
f2 = open(trspath+trsfilename2, 'r')


text = open(pd_path+task+'/text', 'a') # a = append
text2 = open(pd_path+task+'/text2', 'a')
wavscp = open(pd_path+task+'/wav.scp', 'a')
utt2spk = open(pd_path+task+'/utt2spk', 'a')
segments = open(pd_path+task+'/segments', 'a')
#audio_order = open(pd_path+'audio_ordering.sh', 'a')
#if task == 'train':
    #corpus = open('corpus_gosvl.txt', 'a')
#wavscp.write(recording_id+' '+wavfilename)
#audio_path = '"/opt/kaldi/egs/slovenscina/slovenscina_audio/'+task+'"\n'
wavscp.write(recording_id+' sox '+wav_path+recording_id+'.wav  -t wav -c 1 - remix 2|\n')
#audio_order.write('mkdir -p '+audio_path)
#audio_order.write('cp ../../GosVL.wav/'+recording_id+'.wav '+audio_path)
sentence_id = 0
first_utt = True
textline = ''
current_name = False
for line in f:
    #find speakers
    if "<Speaker " in line:
        spkr_id = re.search('id="(.+?)"', line)
        spkr_name = re.search('name="(.+?)"', line)
        spkrs[spkr_id.group(1)] = spkr_name.group(1)
    #find current speaker
    if "<Turn" in line:
        current_id = re.search('speaker="(.+?)"', line)
        if current_id:
            try:
                current_name = spkrs[current_id.group(1)]
            except:
                pass
            
            #audio_order.write('mkdir -p '+audio_path)
            #audio_order.write('cp ../../GosVL.wav/'+recording_id+'.wav '+audio_path)
            
    #extract utterances
    if "<Sync" in line and current_name:        
        utterance_id = str(current_name)+'-'+str(sentence_id+1)
        stop_time = re.search('time="(.+?)"', line)
        if not(first_utt) and len(textline)>0:
            sentence_id += 1
            utt2spk.write(utterance_id+' '+current_name+'\n') # to file 'utt2spk
            #wavscp.write(utterance_id+' /opt/kaldi/egs/slovenscina/slovenscina_audio/train/'+current_name+'/'+wavfilename+str(sentence_id)+'.wav\n') # to file 'wav.scp'
             
            #audio_path = '"/opt/kaldi/egs/slovenscina/slovenscina_audio/train/'+current_name+'"\n'
            #audio_order.write('cp ../../GosVL.s.wav/'+wavfilename+str(sentence_id)+'.wav '+audio_path)
            #audio_order.write('cp ../../GosVL.wav/'+recording_id+'.wav '+audio_path)
            text.write(utterance_id+' '+textline+'\n') # to file 'text'
            segments.write(utterance_id+' '+recording_id+' '+start_time.group(1)+' '+stop_time.group(1)+'\n')
            #if task == 'train':
                #corpus.write(textline+'\n') # to file 'corpus.txt'
            
        else:
            first_utt = False
        textline = ''
        start_time = stop_time
    if len(line)>2 and line[0] != '<':
        textline += line[:-1]
        
sentence_id = 0
first_utt = True
textline = ''        
for line in f2:
    #find speakers
    if "<Speaker " in line:
        spkr_id = re.search('id="(.+?)"', line)
        spkr_name = re.search('name="(.+?)"', line)
        spkrs[spkr_id.group(1)] = spkr_name.group(1)
    #find current speaker
    if "<Turn" in line:
        current_id = re.search('speaker="(.+?)"', line)
        if current_id:
            try:
                current_name = spkrs[current_id.group(1)]
            except:
                pass
    #extract utterances
    if "<Sync" in line and current_name:
        utterance_id = str(current_name)+'-'+str(sentence_id+1)
        if not(first_utt) and len(textline)>0:
            text2.write(utterance_id+' '+textline.lower()+'\n') # to file 'text2'
            sentence_id += 1
        else:
            first_utt = False
        textline = ''
    if len(line)>2 and line[0] != '<':
        textline += line[:-1]        
        
    
    
    #line[:-1]
f.close()
f2.close()
text.close()
text2.close()
utt2spk.close()
#audio_order.close()
segments.close()
#if task == 'train':
    #corpus.close()
# gender of speaker

#spk2gender = open(task+'/spk2gender', 'a')
#f = open(idfilename1, 'r')
#spkr_gender = ''
#spkr_id = ''
#for line in f:
    #if "ID KODA GOVORCA" in line:
        #spkr_id = re.search('ID KODA GOVORCA:\t(.+)',line)
    #if "SPOL" in line:
        #spkr_gender = re.search('SPOL:\t(.+)',line)
#f.close()
#spk2gender.write(spkr_id.group(1)+' '+spkr_gender.group(1)+'\n')
#try:
    #f = open(idfilename2, 'r')
    #for line in f:
        #if "ID KODA GOVORCA" in line:
            #spkr_id = re.search('ID KODA GOVORCA:\t(.+)',line)
        #if "SPOL" in line:
            #spkr_gender = re.search('SPOL:\t(.+)',line)
    #f.close()
    #spk2gender.write(spkr_id.group(1)+' '+spkr_gender.group(1)+'\n')
#except:
    #pass
#spk2gender.close()

#Copyright 2018 Matej Ulčar

#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at

    #http://www.apache.org/licenses/LICENSE-2.0

#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
