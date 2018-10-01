import re
import sys
import glob


task = sys.argv[1]
targetpath = 'local/data_prepare/' #prepared data folder
sofes_path = 'local/raw_data/sofes/Sofes-1.0/' #folder with sofes files
#kaldi_path = '/opt/kaldi/egs/slovenscina/slovenscina_audio/'
text = open(targetpath+task+'/text', 'a')
wavscp = open(targetpath+task+'/wav.scp', 'a')
utt2spk = open(targetpath+task+'/utt2spk', 'a')
#audio_order = open(targetpath+'audio_ordering.sh', 'a')
spk2gender = open(targetpath+task+'/spk2gender', 'a')
#segments = open(targetpath+task+'/segments', 'a')

for txt in glob.iglob(sofes_path+'utterances/**/*m.txt', recursive=True):
    path = txt.split('/')
    utt = path[-1]
    f = open(txt, 'r')
    utt = f.read()
    f.close()
    utterance = re.search('<s> (.+?) </s>', utt)
    utt = utterance.group(1)
    utt_id = path[-1][:-4]
    spkr_name = path[-2]
    spkr_gender = spkr_name[-1]
    
    utt2spk.write(utt_id+' '+spkr_name+'\n')
    text.write(utt_id+' '+utt+'\n')
    spk2gender.write(spkr_name+' '+spkr_gender+'\n')
    
    trs = sofes_path+'utterances/'+spkr_name+'/'+utt_id+'.trs'
    f = open(trs, 'r')
    for line in f:
        if 'startTime' in line:
            start_time = re.search('startTime="(.+?)"', line)
            stop_time = re.search('endTime="(.+?)"', line)
            break
    f.close()

    recording_id = 'rec'+utt_id
    #wavscp.write(recording_id+' sox /opt/kaldi/egs/slovenscina/slovenscina_audio/'+task+'/'+spkr_name+'/'+utt_id+'.wav  -t wav -c 1 - remix 2|\n')
    #wavscp.write(recording_id+' '+kaldi_path+task+'/'+spkr_name+'/'+utt_id+'.wav\n')
    #segments.write(utt_id+' '+recording_id+' '+start_time.group(1)+' '+stop_time.group(1)+'\n')
   # wavscp.write(utt_id+' '+kaldi_path+task+'/'+spkr_name+'/'+utt_id+'.wav\n')
    wavscp.write(utt_id+' '+sofes_path+'utterances/'+spkr_name+'/'+utt_id+'.wav\n')
    
   # audio_path = '"'+kaldi_path+task+'/'+spkr_name+'"\n'
   # audio_order.write('mkdir -p '+audio_path)
   # audio_order.write('cp '+sofes_path+task+'_utterances/'+spkr_name+'/'+utt_id+'.wav '+audio_path)
    
    

text.close()
wavscp.close()
utt2spk.close()
spk2gender.close()
#audio_order.close()
#segments.close()

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
