def izgovori(w):
    w2 = w.lower().replace('x','ks').replace('q','k').replace('ë','e').replace('ï','i').replace('sch','š')
    opc = ['']
    sgl = 'bcčćdđfghjklmnprsštvzž'
    i=0
    if len(w2)>1:
        while i < len(w2)-1:
            if w2[i+1]=='č' and w2[i]=='š': #šč
                opc=[a+'š' for a in opc]+[a+'šč' for a in opc]
                i+=1
            elif w2[i+1]=='j' and w2[i]=='l': #lj
                opc=[a+'l' for a in opc]+[a+'lj' for a in opc]
                i+=1
            elif w2[i+1]=='j' and w2[i]=='n': #nj
                opc=[a+'n' for a in opc]+[a+'nj' for a in opc]
                i+=1
            elif w2[i]=='w': #w
                opc=[a+'w' for a in opc]+[a+'v' for a in opc]    
            elif w2[i+1]=='h' and w2[i]=='c' and i==0: #ch-
                opc=[a+'š' for a in opc]+[a+'č' for a in opc]+[a+'k' for a in opc]
                i+=1
            elif w2[i+1]=='h' and w2[i]=='c' and i>0: #-ch -ch-
                opc=[a+'h' for a in opc]
                i+=1
            elif w2[i+1]=='l' and w2[i] in 'aeio' and i==len(w2)-2: #-!l
                opc=[a+'u' for a in opc]+[a+w2[i]+'w' for a in opc]#+[a+w2[i]+'l' for a in opc]
                return opc
            elif w2[i+1]=='l' and w2[i]=='r' and i==len(w2)-2: #-rl
                opc=[a+'rw' for a in opc]+[a+'ru' for a in opc]
                return opc
            elif w2[i+1]=='v' and w2[i] in 'aeiou' and i==len(w2)-2: #-!v
                opc=[a+w2[i]+'u' for a in opc]+[a+w2[i]+'f' for a in opc]
                return opc
            elif w2[i+1] in sgl and w2[i]=='v': #v&
                opc=[a+'w' for a in opc]
            elif w2[i+1]=='v' and w2[i] in sgl and i==len(w2)-2: #-&v
                opc=[a+w2[i]+'u' for a in opc]+[a+w2[i]+'w' for a in opc]
                return opc
            elif w2[i+1] in 'aeiou' and w2[i]=='y': #y!
                opc=[a+'j' for a in opc]
            elif w2[i+1]=='y' and w2[i] in 'aeiou': #!y
                opc=[a+w2[i]+'j' for a in opc]
                i+=1
            elif w2[i]=='y': #&y&
                opc=[a+'i' for a in opc]
            else:
                opc=[a+w2[i] for a in opc]
            i+=1

    if w2[-1]=='w':
        opc=[a+'w' for a in opc]+[a+'v' for a in opc]
    elif w2[-1]=='y':
        opc=[a+'i' for a in opc]
    else:
        opc=[a+w2[-1] for a in opc]
    
    return opc


sl = open('sloleks-sl_v1.2.tbl', 'r')
lex = open('lexicon_u2.txt', 'w')
ignored = ['0','1','2','3','4','5','6','7','8','9',',','.','-','\'','µ']
for line in sl:
    w = line.split('\t')[0]
    if w[0] not in ignored:
        opc = izgovori(w)
        for o in opc:
            lex.write(w)
            for c in o:
                if c not in ignored:
                    lex.write(' '+c)
            lex.write('\n')
        #lex.write(izgovori(w))
        #for c in w.lower():
            #if c not in ignored:
                #lex.write(' '+c)

sl.close()
lex.close()
    
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
