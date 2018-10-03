This is a kaldi recipe for Slovene language ASR, based on Gos and Sofes speech corpora, and ccGigafida and/or ccKres written corpora.

ASR model is trained by running run.sh script (in s5 folder).

Most important scripts pertaining this recipe are found in subfolders in s5/local/. Folder chain contains scripts for training neural network acoustic model of ASR, folder rnnlm contains scripts for training neural network language models. Folder data_prepare contains various scripts, which parse raw data and prepare it for use with kaldi. The main script for data preparation is prepare_files.sh and is called by run.sh. Data preparation scripts assume the raw data is located in subfolders in s5/local/raw_data as can be seen by viewing individual scripts. If data is located somewhere else, the paths in the scripts need to be edited. Several files are not created by the data preparation scripts and need to be created by hand, however, they're included in the recipe and can be found in folder s5/data/.

---

To je kaldi recept za razpoznavalnik govora za slovenščino. Recept je uporabljen za učenje na govornih korpusih Gos in Sofes ter besedilnih korpusih ccGigafida, oz. ccKres.

Glavna skripta s katero poženemo učenje modela je run.sh, ki se nahaja v mapi s5.

Najpomembnejše skripte, ki se navezujejo posebej na ta recept, se nahajajo v podmapah v s5/local/. V mapi chain so skripte s katerimi naučimo akustični model razpoznavalnika z nevronskimi mrežami. Podobno se nahajajo v mapi rnnlm skripte za učenje jezikovnega modela z nevronskimi mrežami. V mapi data_prepare so skripte s katerimi predobdelamo podatke, tj. korpuse in leksikon, za uporabo s kaldijem. Glavna skripta predobdelave podatkov je prepare_files.sh, ki jo kliče skripta run.sh. Skripte predpostavljajo, da se podatki nahajajo v podmapah v mapi s5/local/raw_data, kot je razvidno iz samih skript. V kolikor imamo podatke shranjenje kje drugje, je potrebno ustrezno popraviti poti v skriptah. Nekaterih potrebnih datotek skripte ne ustvarijo, ampak jih ustvarimo ročno. Te datoteke so sicer že vključene v tem receptu in se nahajajo v mapi s5/data/.
