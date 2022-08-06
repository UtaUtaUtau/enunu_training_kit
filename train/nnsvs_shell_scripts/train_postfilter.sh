# NOTE: the script is supposed to be used called from nnsvs recipes.
# Please don't try to run the shell script directory.

if [ -d conf/train ]; then
    ext="--config-dir conf/train/postfilter"
else
    ext=""
fi

if [ ! -z "${pretrained_expdir}" ]; then
    resume_checkpoint_g=$pretrained_expdir/${postfilter_model}/latest.pth
    if [ -e $pretrained_expdir/${postfilter_model}/latest_D.pth ]; then
        resume_checkpoint_d=$pretrained_expdir/${postfilter_model}/latest_D.pth
    else
        resume_checkpoint_d=
    fi
else
    resume_checkpoint_g=
    resume_checkpoint_d=
fi

# Hyperparameter search with Hydra + optuna
# mlflow is used to log the results of the hyperparameter search
if [[ ${postfilter_hydra_optuna_sweeper_args+x} && ! -z $postfilter_hydra_optuna_sweeper_args ]]; then
    hydra_opt="-m ${postfilter_hydra_optuna_sweeper_args}"
    post_args="mlflow.enabled=true mlflow.experiment=${expname}_${postfilter_model} hydra.sweeper.n_trials=${postfilter_hydra_optuna_sweeper_n_trials}"
else
    hydra_opt=""
    post_args=""
fi

xrun $PYTHON_EXE -m nnsvs.bin.train_postfilter $ext $hydra_opt \
    model=$postfilter_model train=$postfilter_train data=$postfilter_data \
    data.train_no_dev.in_dir=$expdir/acoustic/norm/$train_set/in_postfilter \
    data.train_no_dev.out_dir=$dump_norm_dir/$train_set/out_postfilter \
    data.dev.in_dir=$expdir/acoustic/norm/$dev_set/in_postfilter \
    data.dev.out_dir=$dump_norm_dir/$dev_set/out_postfilter \
    data.in_scaler_path=$expdir/acoustic/norm/in_postfilter_scaler.joblib \
    data.out_scaler_path=$dump_norm_dir/out_postfilter_scaler.joblib \
    data.sample_rate=$sample_rate \
    train.out_dir=$expdir/${postfilter_model} \
    train.resume.netG.checkpoint=$resume_checkpoint_g \
    train.resume.netD.checkpoint=$resume_checkpoint_d $post_args