#!/bin/bash


kaldi_proj_path=$KALDI_ROOT
dp_path=$kaldi_proj_path/local/data_prepare

train_files=( )
test_files=(GosVL01_pravo_s3.trs  GosVL05_zsrce_s3.trs  GosVL09_ocean_s3.trs  GosVL13_menin_s3.trs  GosVL17_inten_s3.trs  GosVL21_poraz_s3.trs  GosVL25_nanom_s3.trs GosVL02_kleme_s3.trs  GosVL06_kzcoi_s3.trs  GosVL10_partn_s3.trs  GosVL14_karci_s3.trs  GosVL18_aritm_s3.trs  GosVL22_siste_s3.trs GosVL03_medit_s3.trs  GosVL07_kungf_s3.trs  GosVL11_lhise_s3.trs  GosVL15_celia_s3.trs  GosVL19_pujsk_s3.trs  GosVL23_jeklo_s3.trs GosVL04_fitot_s3.trs  GosVL08_droge_s3.trs  GosVL12_cujec_s3.trs  GosVL16_stara_s3.trs  GosVL20_zumer_s3.trs  GosVL24_inter_s3.trs) #s3.trs datoteke

mkdir -p $dp_path/train
mkdir -p $dp_path/test
mkdir -p $dp_path/dev
mkdir -p $dp_path/traindev/sorted
mkdir -p $kaldi_proj_path/data/train
mkdir -p $kaldi_proj_path/data/dev
mkdir -p $kaldi_proj_path/data/test

# remove old files
#rm audio_ordering.sh
rm $dp_path/train/*
rm $dp_path/test/*
rm $dp_path/dev/*
rm $dp_path/traindev/*
rm $dp_path/traindev/sorted/*
# rm lexicon_dup.txt
# rm corpus.txt

# create traindev files
echo "Creating train and dev files"

python3 $dp_path/gos_parser.py traindev || exit 1
echo "gos parsed"
python3 $dp_path/sofes_parser.py traindev || exit 1
echo "sofes parsed"

# split train and dev
#python3 split_train_dev.py || exit 1
#rm -r traindev


# create test files
echo "Creating test files"
for i in "${test_files[@]}" 
do
    python3 $dp_path/parse_trs_segments.py test "$i" || exit 1;
done
# python3 sofes_parser.py test || exit 1
# create lexicon
# python3 lexicon_gosvl.py
cp $dp_path/spklist1 $dp_path/traindev/spk2gender
cp $dp_path/spklist2 $dp_path/test/spk2gender

echo "Sorting"
#export LC_ALL=C
LC_ALL=C sort -u $dp_path/traindev/utt2spk > $dp_path/traindev/sorted/utt2spk
LC_ALL=C sort -u $dp_path/traindev/wav.scp > $dp_path/traindev/sorted/wav.scp
LC_ALL=C sort -u $dp_path/traindev/spk2gender > $dp_path/traindev/sorted/spk2gender
LC_ALL=C sort -u $dp_path/traindev/text > $dp_path/traindev/sorted/text
python3 $dp_path/split_train_dev.py || exit 1;

LC_ALL=C sort -u $dp_path/train/utt2spk > ${kaldi_proj_path}/data/train/utt2spk
LC_ALL=C sort -u $dp_path/train/wav.scp > ${kaldi_proj_path}/data/train/wav.scp
LC_ALL=C sort -u $dp_path/train/spk2gender > ${kaldi_proj_path}/data/train/spk2gender
LC_ALL=C sort -u $dp_path/train/text > ${kaldi_proj_path}/data/train/text
LC_ALL=C sort -u $dp_path/dev/utt2spk > ${kaldi_proj_path}/data/dev/utt2spk
LC_ALL=C sort -u $dp_path/dev/wav.scp > ${kaldi_proj_path}/data/dev/wav.scp
LC_ALL=C sort -u $dp_path/dev/spk2gender > ${kaldi_proj_path}/data/dev/spk2gender
LC_ALL=C sort -u $dp_path/dev/text > ${kaldi_proj_path}/data/dev/text


LC_ALL=C sort -u $dp_path/test/utt2spk > ${kaldi_proj_path}/data/test/utt2spk
LC_ALL=C sort -u $dp_path/test/wav.scp > ${kaldi_proj_path}/data/test/wav.scp
LC_ALL=C sort -u $dp_path/test/spk2gender > ${kaldi_proj_path}/data/test/spk2gender
LC_ALL=C sort -u $dp_path/test/text > ${kaldi_proj_path}/data/test/text
LC_ALL=C sort -u $dp_path/test/segments > ${kaldi_proj_path}/data/test/segments

echo "Preparing written corpus"
cat $kaldi_proj_path/local/raw_data/gigafida/ccGigafidaV1_0-text/* > $kaldi_proj_path/local/raw_data/gigafida/corpus.txt
python3 $dp_path/prepare_corpus.py

echo "Preparing lexicon"
python3 $dp_path/sloleks2lex.py
echo "<UNK> spn" >> $dp_path/lexicon_u.txt
echo "() ()" >> $dp_path/lexicon_u.txt
LC_ALL=C sort -u $dp_path/lexicon_u.txt > $kaldi_proj_path/data/local/dict/lexicon.txt

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
