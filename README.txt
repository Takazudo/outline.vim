=====================================================================
outline.vim

Author:      Takeshi Takatsudo <takazudo@gmail.com>
Llicense:    Licensed under the same terms as Vim itself.
Description: outline.vim is a vim plugin.
             This plugins creates an outline window for commented documents.
				 Here's a example.
=====================================================================

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

=====================================================================
	exe ":Oo".
	outline.vim creates following outlineBuf in the left side.
=====================================================================

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

=====================================================================
	see outline.vim for further information.
=====================================================================
