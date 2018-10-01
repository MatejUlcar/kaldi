import re
import sys

gos_path = 'local/raw_data/gos/' #folder with transcription
pd_path = 'local/data_prepare/' #prepared data folder
audio_path = 'local/raw_data/gos/GOS-zvocne/' #folder with audio files

task = sys.argv[1] #train ali test
f = open(gos_path+'TEI_GOS.xml', 'r')

text = open(pd_path+task+'/text', 'a') # a = append
#text2 = open(pd_path+task+'/text2', 'a')
wavscp = open(pd_path+task+'/wav.scp', 'a')
utt2spk = open(pd_path+task+'/utt2spk', 'a')
spk2gender = open(pd_path+task+'/spk2gender', 'a')
#segments = open(pd_path+task+'/segments', 'a')

utterance = ""
utt_id = False
current_speaker = False
parsed_utterances = []
text_type = False
body = False
for line in f:
    #find start
    if "<TEI" in line:
        body = True
    elif "</TEI" in line:
        body = False
    
    #find title
    if body and "<title" in line:
        title = re.search('xml:id="(.+?)"', line)
    
    #find speakers
    if body and "<person" in line:
        speaker_name = re.search('n="(.+?)"', line)
        speaker_name = speaker_name.group(1)
    if body and "<sex" in line:
        speaker_sex = re.search('>(.+?)<\/sex>', line)
        speaker_sex = speaker_sex.group(1)
        if speaker_sex == 'moški':
            speaker_gender = 'm'
        elif speaker_sex == 'ženski':
            speaker_gender = 'f'
        else:
            speaker_gender = speaker_name[1]
        if speaker_gender != 'm' and speaker_gender != 'f':
            speaker_gender = 'f'
        spk2gender.write(speaker_name+" "+speaker_gender+'\n')
    
    #find text
    if body and "<div type" in line:
        text_type = re.search('type="(.+?)"', line)
        text_type = text_type.group(1)
        
    if text_type == "norm" and "<u who" in line:
        new_speaker = re.search('who="(.+?)"', line)
        new_speaker = new_speaker.group(1)
        new_speaker = new_speaker.split()[0] #vzamem samo prvega govorca, ce jih je v enem stavku vec, omejitev kaldija, ne more biti v enem utt vec govorcev
        if not current_speaker:
            current_speaker = new_speaker

    if text_type == "norm" and "<seg xml:id" in line:
        new_utt_id = re.search('synch="(.+?)"', line)
        new_utt_id = new_utt_id.group(1)
        if utt_id and utt_id != new_utt_id and len(utterance[:-1])>0:
            text.write(current_speaker+'-'+utt_id+" "+utterance[:-1]+"\n")
            utt2spk.write(current_speaker+'-'+utt_id+" "+current_speaker+"\n")
            parsed_utterances.append(utt_id)
            #wavscp.write(current_speaker+'-'+utt_id+' sox '+audio_path+'/'+utt_id+'.wav  -t wav -c 1 - remix 2|\n')
            wavscp.write(current_speaker+'-'+utt_id+' '+audio_path+'/'+utt_id+'.wav\n')
            utterance = ''
            current_speaker = new_speaker
        utt_id = new_utt_id
        
    if text_type == "norm" and "</w>" in line and "<w" in line:
        word = re.search('>(.+?)<\/w>', line)
        utterance += word.group(1)+' '

    if text_type == "norm" and ("<pause/>" in line or "<gap/>" in line or "<gap reason=" in line):
        utterance += '() '

    if text_type == "norm" and ("unclear>" in line or "<vocal" in line):
        utterance += '<UNK> '

    if text_type == "norm" and "<name" in line:
        utterance += '<UNK> '
    #if text_type == "norm" and "</seg>" in line:
        
        #if utt_id not in parsed_utterances:
            
        


f.close()
text.close()
wavscp.close()
utt2spk.close()
spk2gender.close()

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
