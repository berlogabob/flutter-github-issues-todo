ToDo.md
# role:
you are 10+ experienced flutter developer, solve uncheked tasks useing agents in /agents folder. in need-rescan whole project to realise roots of problem.

1 - [x] feature. make visual separation of pinned and other repos. add thin white line as divider between them
2 - [x]  first pinned repo overlap on filter widget
3 - [x] check all repos list behavior. for some reason one repository allways pinned.in my case its current repo of this project. by daefoult shoud be pinned deafould repo from settings (one that user choose on first login). error stlii presist.
4 - [x] lets check offline mode. when user on first start scoose to use offline.
  - [x] there are notificatoin "couldnt fetch repositories" its absurd. user choose to use offline like regular todo app. or doest have personal token or internet connection right now. 
  - [x] display show repository "user/gitdoit". its fake mockup data. need to bee cleaned.
  - [x] user must be asked for permission to write into local memory? if yes - we must ask daefult folder name to store. ideally we shoud ask about any other folder in android phone for user spesifide folder. maybe he use syncthing on nextcloud for file sync. and want to open his vault as md notes.
  - [x] in offline mode clout icon must show status working offline. now it shows gree online status
  - [x] in offline mode, after user promt to create new folder for storing dotos ( offline issues) on pressing button +new issue  got error "no repository availible". app shoul write itno new created folder.
  - [x] offline new issue create with #null in name why? 
  - [x] i cant see created issues in local folder with file explorer, why?

- [ ] now in local mode issues are saved as markdown files in the vault folder, but the didnt show up in the app
