=====================================================================
outline.vim

Author:      Takeshi Takatsudo <takazudo@gmail.com>
Version:     0.4
LastUpdate:  2009-11-29
Llicense:    Licensed under the same terms as Vim itself.
Description: outline.vim is a vim plugin. This plugin creates
             an outline window for commented documents.
=====================================================================
* Here's an example.

/**
 * treeNodeA
 */
node comtrents

	/**
	 * treeNodeB
	 */
	node comtrents

		/**
		 * treeNodeC
		 */
		node comtrents
		
			/**
			 * treeNodeD
			 */
			node comtrents

		/**
		 * treeNodeE
		 */
		node comtrents

	/**
	 * treeNodeF
	 */
	node comtrents

		/**
		 * treeNodeG
		 */
		node comtrents

---------------------------------------------------------------------
	exe ":Oo".
	outline.vim creates following outlineBuf in the left side.
---------------------------------------------------------------------

   .---------------------------------------------------------------
   |treeNodeA         | /**
   |  treeNodeB       |  * treeNodeA
   |    treeNodeC     |  */
   |      treeNodeD   | node contents
   |    treeNodeE     | 
   |  treeNodeF       |     /**
   |    treeNodeG     |      * treeNodeB
   |                  |      */
   |                  |     node contents
   |                  | 
   |                  |         /**
   |                  |          * treeNodeC
   |                  |          */
   |                  |         node contents
   .                  .

---------------------------------------------------------------------
	see outline.vim for further information.

=====================================================================
* ChangeLog

0.4 (2009-11-29)
	- Add feature: "AutoFocus" When you enter outlineBuf,
	  associated node will be focused automatically.
	- Bug fix: If you exe :ToOutline in the lines above first comment,
	  outline.vim didnot work correctly.

0.31 (2009-11-29)
	- Refactoring update.
	- Bug Fix: Some errors caused by GUI tabs fixed.

0.3 (2009-11-28)
	- Bug fix: Troubles fixed in refreshing if parentBuf and outlineBuf
	  were in different GUI tabs.
	- Whitespace chars in outlineBuf were changed to tabs from spaces.

0.2 (2009-11-25)
	- Bug fix: Refreshing outlineBuf didn't work correctly
	  if total comments' num in parentBuf got decreased.
	- Cursor focus to outlineBuf after refreshing avoided.

0.1 (2009-11-23)
	- Initial release


=====================================================================
* ToDo

	- Allow custom outline patterns.
	- Allow coloring outlineBuf.
	- Allow spaces instead of tabs to detect nodes.


