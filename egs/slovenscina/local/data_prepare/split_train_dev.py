spk2gender = open('local/data_prepare/traindev/sorted/spk2gender', 'r')
t_spk2gender = open('local/data_prepare/train/spk2gender', 'w')
d_spk2gender = open('local/data_prepare/dev/spk2gender', 'w')
train_spk = []
dev_spk = []
counter=1
for line in spk2gender:
    if counter%11==0:
        d_spk2gender.write(line)
        dev_spk.append(line.split()[0])
    else:
        t_spk2gender.write(line)
        train_spk.append(line.split()[0])
    counter+=1

spk2gender.close()
t_spk2gender.close()
d_spk2gender.close()

utt2spk = open('local/data_prepare/traindev/sorted/utt2spk', 'r')
t_utt2spk = open('local/data_prepare/train/utt2spk', 'w')
d_utt2spk = open('local/data_prepare/dev/utt2spk', 'w')
train_utt = []
dev_utt = []
for line in utt2spk:
    if line.split()[1] in dev_spk:
        d_utt2spk.write(line)
        dev_utt.append(line.split()[0])
    else:
        t_utt2spk.write(line)
        train_utt.append(line.split()[0])

utt2spk.close()
t_utt2spk.close()
d_utt2spk.close()

text = open('local/data_prepare/traindev/sorted/text', 'r')
t_text = open('local/data_prepare/train/text', 'w')
d_text = open('local/data_prepare/dev/text', 'w')
for line in text:
    if line.split()[0] in dev_utt:
        d_text.write(line)
    else:
        t_text.write(line)
text.close()
t_text.close()
d_text.close()

wavscp = open('local/data_prepare/traindev/sorted/wav.scp', 'r')
t_wavscp = open('local/data_prepare/train/wav.scp', 'w')
d_wavscp = open('local/data_prepare/dev/wav.scp', 'w')
for line in wavscp:
    if line.split()[0] in dev_utt:
        d_wavscp.write(line)
    else:
        t_wavscp.write(line)
wavscp.close()
t_wavscp.close()
d_wavscp.close()

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
