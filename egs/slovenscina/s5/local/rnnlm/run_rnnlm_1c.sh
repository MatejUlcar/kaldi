#!/bin/bash

# Copyright 2012  Johns Hopkins University (author: Daniel Povey)
#           2015  Guoguo Chen
#           2017  Hainan Xu
#           2017  Xiaohui Zhang
#           2018  Matej Ulčar

# This script trains LMs on the swbd LM-training data.


# Begin configuration section.

dir=exp/rnnlm/lstm_1c
embedding_dim=512
lstm_rpd=200
lstm_nrpd=200
epochs=15
stage=5
train_stage=-10

# variables for lattice rescoring
run_lat_rescore=false
run_nbest_rescore=true
run_backward_rnnlm=false

#ac_model_dir=exp/nnet3/tdnn_lstm_1a_adversarial0.3_epochs12_ld5_sp
ac_model_dir=exp/chain/tdnn1a_sp
decode_dir_suffix=lstm_1c
ngram_order=3 # approximate the lattice-rescoring by limiting the max-ngram-order
              # if it's set, it merges histories in the lattice if they share
              # the same ngram history and this prevents the lattice from 
              # exploding exponentially
pruned_rescore=true

. ./cmd.sh
. ./utils/parse_options.sh

text=data/local/corpus_kres.txt
# fisher_text=data/local/lm/fisher/text1.gz
#lexicon=data/local/dict/lexiconp.txt
wordlist=data/lang/words.txt
text_dir=data/rnnlm
mkdir -p $dir/config
set -e

for f in $text $wordlist; do
  [ ! -f $f ] && \
    echo "$0: expected file $f to exist" && exit 1
done

if [ $stage -le 0 ]; then
  echo "-- stage 0 --"
  mkdir -p $text_dir
  echo -n >$text_dir/dev.txt
  # hold out one in every 500 lines as dev data.
  cat $text | cut -d ' ' -f2- | awk -v text_dir=$text_dir '{if(NR%500 == 0) { print >text_dir"/dev.txt"; } else {print;}}' >$text_dir/slv.txt
#   cat > $dir/config/hesitation_mapping.txt <<EOF
# hmm hum
# mmm um
# mm um
# mhm um-hum 
# EOF
#   gunzip -c $fisher_text | awk 'NR==FNR{a[$1]=$2;next}{for (n=1;n<=NF;n++) if ($n in a) $n=a[$n];print $0}' \
#     $dir/config/hesitation_mapping.txt - > $text_dir/fisher.txt
fi

if [ $stage -le 1 ]; then
  echo "-- stage 1 --"
  cp $wordlist $dir/config/
  n=`cat $dir/config/words.txt | wc -l`
  echo "<brk> $n" >> $dir/config/words.txt
# 
#   # words that are not present in words.txt but are in the training or dev data, will be
#   # mapped to <SPOKEN_NOISE> during training.
  echo "<UNK>" >$dir/config/oov.txt
# 
  cat > $dir/config/data_weights.txt <<EOF
slv   1   1.0
EOF

  rnnlm/get_unigram_probs.py --vocab-file=$dir/config/words.txt \
                             --unk-word="<UNK>" \
                             --data-weights-file=$dir/config/data_weights.txt \
                             $text_dir | awk 'NF==2' >$dir/config/unigram_probs.txt

  # choose features
  rnnlm/choose_features.py --unigram-probs=$dir/config/unigram_probs.txt \
                           --use-constant-feature=true \
                           --special-words='<s>,</s>,<UNK>,<brk>' \
                           $dir/config/words.txt > $dir/config/features.txt

  cat >$dir/config/xconfig <<EOF
input dim=$embedding_dim name=input
fast-lstm-layer name=lstm1 cell-dim=$embedding_dim
fast-lstm-layer name=lstm2 cell-dim=$embedding_dim
fast-lstm-layer name=lstm3 cell-dim=$embedding_dim
output-layer name=output include-log-softmax=false dim=$embedding_dim
EOF
  rnnlm/validate_config_dir.sh $text_dir $dir/config
fi

if [ $stage -le 2 ]; then
  echo "-- stage 2 --"
  rnnlm/prepare_rnnlm_dir.sh --unigram-factor 200.0 $text_dir $dir/config $dir
fi

if [ $stage -le 3 ]; then
  echo "-- stage 3 --"
  rnnlm/train_rnnlm.sh --num-jobs-initial 1 --num-jobs-final 1 \
                  --stage $train_stage --num-epochs $epochs --use_gpu_for_diagnostics true --cmd "$train_cmd" $dir
fi

#LM=big # old lm
if [ $stage -le 4 ] && $run_lat_rescore; then
  echo "-- stage 4 --"
  echo "$0: Perform lattice-rescoring on $ac_model_dir"
#  LM=sw1_tg # if using the original 3-gram G.fst as old lm
  pruned=
  if $pruned_rescore; then
    pruned=_pruned
  fi
  test_sets="dev_gos test"
  for tset in $test_sets; do
    decode_dir=${ac_model_dir}/decode_${tset}
    # Lattice rescoring
    rnnlm/lmrescore$pruned.sh \
        --cmd run.pl --num-threads 14\
        --weight 0.45 --max-ngram-order $ngram_order \
        data/lang $dir \
        data/${tset}_hires ${decode_dir} \
        ${decode_dir}_${decode_dir_suffix}_0.45
   done

fi

if [ $stage -le 5 ] && $run_nbest_rescore; then
  echo "-- stage 5 --"
  echo "$0: Perform nbest-rescoring on $ac_model_dir"
    test_sets="dev_sofes dev_gos test"
    for tset in $test_sets; do
      decode_dir=${ac_model_dir}/decode_${tset}

      # Lattice rescoring
      rnnlm/lmrescore_nbest.sh \
        --cmd "$decode_cmd" --N 50 \
        0.8 data/lang $dir \
        data/${tset}_hires ${decode_dir} \
        ${decode_dir}_${decode_dir_suffix}_nbest
    done
fi

# running backward RNNLM, which further improves WERS by combining backward with
# the forward RNNLM trained in this script.
if [ $stage -le 6 ] && $run_backward_rnnlm; then
  local/rnnlm/run_tdnn_lstm_back.sh
fi

exit 0
