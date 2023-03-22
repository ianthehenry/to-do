# `to do`

This is a very simple to-do list with an interface powered by `fzf`.

It stores tasks in a plain-text format inspired by GitHub-flavored Markdown's task lists:

```
- [ ] this is a thing to do
- [x] already done
- [-] nah nevermind
- [ ] but i should still do this
```

The CLI is very simple:

```shell
$ to do # print todo list

$ to do 'add a new task'

$ to did # mark something completed

$ to did 'add an already completed task'

$ to dont # mark something won't-do

$ to undo # unmark a task

$ to edit # open in $EDITOR
```

In order to use it, you need `fzf` installed, Janet, plus the Janet dependencies [`cmd`](https://github.com/ianthehenry/cmd) and [`sh`](https://github.com/andrewchambers/janet-sh).

```
$ jpm install sh
$ jpm install cmd
```

I also highly recommend [`zsh-autoquoter`](https://github.com/ianthehenry/zsh-autoquoter/), which lets you add tasks items without needing to quote them on the command line.
