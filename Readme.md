# yafootnote

`yafootnote` is yet another LaTeX `footnote` implementation with LuaTeX. 
It can be placed not only on main vertical lists but also on mimpage like boxes, namely mdframed and tcolorbox, and even within a plain old `footnote` command.

**NOTE** : This implementation is a sort of PoC status for now.
You can't expect it works in any practical LuaLaTeX documents.
It has still a lot of problems, especially when working with vsplited boxes, though it could be used practically within such boxes like a breakable tcolorbox. 

Known issue is that it doesn't work with floating tcolorbox. In addition to that, if the floating tcolorbox is breakable and when the break actually happen, the footnote just before the tcolorbox would be doubled.

## Demo

https://www.overleaf.com/read/pgjqvgqrxvsj

## License

The MIT License.

