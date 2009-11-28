=====================================================================
outline.vim

Author:      Takeshi Takatsudo <takazudo@gmail.com>
Version:     0.3
LastUpdate:  2009-11-28
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

0.3 (2009-11-28)
	- Bug fix: Got trouble in refreshing when parentBuf and outlineBuf
	  were in different GUI tab.
	- Whitespace chars in outlineBuf were changed to tabs from spaces.

0.2 (2009-11-25)
	- Bug fix: refreshing outlineBuf didn't work correctly
	  when node num got decreased.
	- Cursor focus to outlineBuf after refresh avoided.

0.1 (2009-11-23)
	- Initial release


=====================================================================
* ToDo

	- Allow custom outline patterns.
	- Allow coloring outlineBuf.
	- Allow spaces instead of tabs to detect nodes.


