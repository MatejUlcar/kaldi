import sys
import string

c_path = 'local/raw_data/gigafida/' #folder with one corpus.txt file
pd_path = 'local/data_prepare/' #prepared data folder

f = open(c_path+'corpus.txt', 'r')
corpus = open(pd_path+'corpus.txt', 'w')

trans = str.maketrans('','',string.punctuation)
for line in f:
    if not len(line) <= 1:
        corpus.write(' '.join(line.translate(trans).split())+'\n')

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
