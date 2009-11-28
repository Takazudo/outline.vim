/**
 * $.inPageDialog
 * @version    0.2  (updated: 2009/10/28)
 * @author     Takeshi Takatsudo (http://zudolab.net/blog/)
 * @license    MIT (http://www.opensource.org/licenses/mit-license.php)
 */
(function($){ // start $ encapsulation

/**
 * common
 */
var whileAnimation = false;

/* cache for reuse */
var $win=$(window);
var $doc=$(document);
var $body;
$(function(){ $body=$(document.body); });

/* extend browser object */
$.browser.msie6 = ($.browser.msie && $.browser.version==="6.0");
	
/**
 * $.overlay
 */
$.overlay = (function(){
	
	var o = {};
	o.options = {
		opacity: 0.8,
		iframeSrc: 'javascript:', // the src of the overlay iframe. specify empty file or something
		loadingImgPath: 'loading.gif',
		fadeSpeed: 200
	};
	o.color = null; // color overlay
	o.iframe = null; // iframe overlay
	o.loading = null; // loading overlay
	
	/* callbacks */
	o.onShow = null; // executed when the colorOverlay was opened
	o.onHide = null; // executed when the colorOverlay was closed
	
	/**
	 * .show()
	 */
	o.show = function(){
		if(o.color){ o.color.show(); }
		if(o.iframe){ o.iframe.show(); }
		if(o.loading){ o.loading.show(); }
	};

	/**
	 * .hide()
	 */
	o.hide = function(){
		if(o.color){ o.color.hide(); }
		if(o.iframe){ o.iframe.hide(); }
		if(o.loading){ o.loading.hide(); }
	};

	/**
	 * .isPrepared()
	 */
	o.isPrepared = function(){
		return (o.color && o.iframe && o.loading) ? true : false;
	};

	/**
	 * .reset()
	 */
	o.reset = function(){
		if(o.color){ o.color.empty().remove(); }
		if(o.iframe){ o.iframe.empty().remove(); }
		if(o.loading){ o.loading.empty().remove(); }
		o.color = null;
		o.iframe = null;
		o.loading = null;
		o.onShow = null;
		o.onHide = null;
	}

	/**
	 * .prepare()
	 */
	o.prepare = function(){
	
		if(o.isPrepared()){ return; }
		o.color = $('<div id="inPageDialog_colorOverlay"></div>');
		o.loading = $('<div id="inPageDialog_loading"><table><tr><td><img src="'+o.options.loadingImgPath+'" alt="" /></td></tr></table></div>');
		o.iframe = $('<iframe id="inPageDialog_iframeOverlay" frameborder="0" src="'+o.options.iframeSrc+'"></iframe>');
		
		/**
		 * color overlay
		 */
		o.color.css('opacity',o.options.opacity);
		o.color.show = function(){
			if(this.is('visible')){ return this; }
			this.setPosition().css('display','block');
			if(o.onShow){ o.onShow(); }
			return this;
		};
		o.color.hide = function(){
			if(!this.is(':visible')){ return this; }
			var self = this;
			if($.browser.msie){
				this.css('display','none'); /* IE ignore opacity when fadeOut so avoid it */
				if(o.onHide){ o.onHide(); }
			}else{
				whileAnimation = true;
				this.fadeOut(o.options.fadeSpeed,function(){
					whileAnimation = false;
					if(o.onHide){ o.onHide(); }
				});
			}
			return this;
		};
		
		/**
		 * loading overlay
		 */
		o.loading.show = function(){
			if(this.is(':visible')){ return this; }
			this.setPosition();
			var self = this;
			setTimeout(function(){ // make short delay to avoid this comes in front of the color overlay
				if($.browser.msie6){
					self.css({
						'top': $doc.scrollTop(),
						'height': $win.height(),
						'display': 'block'
					});
				}else{
					self.css('display','block');
				}
			},4);
			return this;
		};
		o.loading.hide = function(){ return this.css('display','none'); };
		
		/**
		 * iframe overlay
		 */
		o.iframe.css('opacity',0);
		o.iframe.show = function(){
			if(this.is('visible')){ return this; }
			return this.setPosition().css('display','block');
		}
		o.iframe.hide = function(){ return this.css('display','none'); }
		
		/**
		 * extend each overlays
		 */
		$.each([o.color, o.iframe, o.loading], function(){
			/**
			 * setPosition
			 * IE6 doesnot support position:fixed. so, use absolute instead.
			 * this method will expand the overlays to fullsize.
			 */
			this.setPosition = function(){
				if(!$.browser.msie6){ return this };
				return this.css({
					'top' : $doc.scrollTop(),
					'left' : $doc.scrollLeft(),
					'width' : $win.width(),
					'height' : $win.height()
				});
			};
			$body.append(this);
			/**
			 * bindOvelayAdjustEvents
			 * IE6 doesnot support position:fixed. so, use absolute instead.
			 * this method will adjust the overlays' position when scroll and resize.
			 */
			var self = this;
			(function(){
				if(!$.browser.msie6) return;
				$win.bind('resize scroll', function(){
					if(!$.inPageDialog.currentDialog){ return; }
					if(!self.is(':visible')){ return; }
					self.setPosition();
				});
			})();
			this.click(function(){
				if($.inPageDialog){ $.inPageDialog.close(); }
			});
			
		}); // extend overlays
		
	}; // o.prepare()
	
	return o;
	
})(); // $.overlay

/**
 * $.inPageDialog
 */
$.inPageDialog = (function(){

	var o = {};
	o.options = {
		fadeSpeed: 200,
		useNoCache : false,
		width: null,
		height: null,
		extraClass: null,
		altAsTitle: false,
		selector_closeButton: "a.js_inPageDialog_close",
		selector_locChangeA: "a.js_inPageDialog_locChangeA",
		selector_locChangeForm: "form.js_inPageDialog_locChangeForm",
		dialogHtml:'\
			<div class="inPageDialog_container">\
				<table class="inPageDialog_posTable"><tr><td class="inPageDialog_posTd">\
					<div class="inPageDialog_inTableContainer">\
						<div class="inPageDialog_titleBar">\
							<p class="inPageDialog_closeBtn"><a href="#"><img src="close.gif" alt="" /></a></p>\
							<p class="inPageDialog_title"></p>\
						</div>\
						<div class="inPageDialog_content"></div>\
					</div>\
				</td></tr></table>\
			</div>\
		',
		opener: null,
		type: null
	};
	
	/* store dialogSet, dialog */
	o.currentDialogSet = null;
	o.currentDialog = null;
	
	/* store dialogSets */
	o.dialogSets = [];
	
	/**
	 * .create(options)
	 * create dialogSet
	 */
	o.create = function(options){
		options = $.extend({},o.options,options);
		var dialogSet;
		switch(options.type){
			case "img": dialogSet = createSet_imgDialog(options); break;
			case "ajax": dialogSet = createSet_ajaxDialog(options); break;
			case "iframe": dialogSet = createSet_iframeDialog(options); break;
			case "anchor": dialogSet = createSet_anchorDialog(options); break;
			default: break;
		}
		if(dialogSet){
			o.dialogSets.push(dialogSet);
			return dialogSet;
		}else{
			return null;
		}
	};
	
	/**
	 * .close()
	 */
	o.close = function(){
		if(this.currentDialog){
			this.currentDialog.close();
		}else{
			$.overlay.hide();
		}
	};
	
	/**
	 * .reset()
	 */
	o.reset = function(){
		o.close();
		o.currentDialogSet = null;
		o.currentDialog = null;
		o.dialogSets.length = 0;
		$.overlay.reset();
	};
	
	return o;
	
})();

/**
 * $.fn.inPageDialog(options)
 * jQuery interface
 */
$.fn.inPageDialog = function(options){
	var dialogSet = $.inPageDialog.create($.extend({},options,{opener:this}));
	this.dialogSet = dialogSet; // store dialogSet as member of the jQuery object.
	return this;
};

/**
 * createSet_base(options)
 */
var createSet_base = function(options){

	var set = {};
	set.dialogs = [];
	if(!options.opener.size()){ return set; }
	
	/**
	 * extend opener
	 */
	options.opener.each(function(){
	
		var opener = $(this);
		
		opener.click(function(e){
		
			e.preventDefault();
			if($.inPageDialog.currentDialog){
				return;
			}
			if(whileAnimation){ return; }
			whileAnimation = true; // set animation start flag
			opener.blur();
			$.inPageDialog.currentDialogSet = set;
			set.open(opener.info());
			
		});
		
		/**
		 * .open(info)
		 */
		set.open = function(info){
			
			var dialog;
			
			$.each(set.dialogs, function(){
				if(this.url!==info.url){ return; }
				if(this.title!==info.title){ return; }
				if(this.width && this.width!==info.width){ return; }
				if(this.height && this.height!==info.height){ return; }
				dialog = this;
				dialog.open();
				return false;
			});
			if(!dialog){
			
				dialog = set.createDialog($.extend({},$.inPageDialog.options,options,info));
				set.dialogs.push(dialog);
			}
			
			return dialog;
			
		}; // set.open()
		
		/**
		 * opener.info
		 */
		opener.info = function(){
		
			var info = {};
			attachUrl(info);
			attachTitle(info);
			attachScale(info);
			return info;
		
			function attachUrl(info){
				info.url = opener.attr("href");
			}
			function attachTitle(info){
				info.title = opener.attr("title") || null;
				if(options.altAsTitle){
					var altVal = opener.find("img").eq(0).attr("alt");
					if(altVal){ info.title = altVal; }
				}
			}
			function attachScale(info){
				info.width = null;
				info.height = null;
				if(opener.is("[class*= w_]")){
					$.each(opener.attr("class").split(" "),function(){
						if(this.indexOf("w_")!==0) return;
						$.each(this.split("_"),function(i){
							if(i===1){ info.width = this; }
							if(i===3){ info.height = this; }
						});
						return false;
					});
				}
			}
			
		}; // opener.info()
		
	}); // options.opener.each()
	
	return set;
	
}; // createSet_base

/**
 * createSet_*(options)
 * extended factories
 */
	/**
	 * createSet_imgDialog(options)
	 */
	function createSet_imgDialog(options){
		var dialogSet = createSet_base(options);
		dialogSet.createDialog = createDialog_img;
		return dialogSet;
	};
	/**
	 * createSet_ajaxDialog(options)
	 */
	function createSet_ajaxDialog(options){
		var dialogSet = createSet_base(options);
		dialogSet.createDialog = createDialog_ajax;
		return dialogSet;
	};
	/**
	 * createSet_iframeDialog(options)
	 */
	function createSet_iframeDialog(options){
		var dialogSet = createSet_base(options);
		dialogSet.createDialog = createDialog_iframe;
		return dialogSet;
	};
	/**
	 * createSet_anchorDialog(options)
	 */
	function createSet_anchorDialog(options){
		var dialogSet = createSet_base(options);
		dialogSet.createDialog = createDialog_anchor;
		return dialogSet;
	};


/**
 * createDialog_base(options)
 */
var createDialog_base = function(options){

	$.overlay.prepare();
	
	var $dialog = $(options.dialogHtml);
	$dialog.$posTable = $dialog.find('table.inPageDialog_posTable').eq(0);
	$dialog.$posTd = $dialog.find('td.inPageDialog_posTd').eq(0);
	$dialog.$inTableContainer = $dialog.find('div.inPageDialog_inTableContainer').eq(0);
	$dialog.$titleBar = $dialog.find('div.inPageDialog_titleBar').eq(0);
	$dialog.$title = $dialog.find('p.inPageDialog_title').eq(0);
	$dialog.$closeBtn = $dialog.find('p.inPageDialog_closeBtn a').eq(0);
	$dialog.$content = $dialog.find('div.inPageDialog_content').eq(0);
	if(options.extraClass){ $dialog.addClass(options.extraClass); }
	if(options.width){ $dialog.$content.css('width',options.width); }
	if(options.height){ $dialog.$content.css('height',options.height); }
	if(options.title){ $dialog.$title.text(options.title); }
	$dialog.url = options.url;
	
	/**
	 * bindInsideEvents()
	 */
	$dialog.bindInsideEvents = function(){
	
		/* set event to closeButtons */
		$dialog.find(options.selector_closeButton).click(function(e){
			e.preventDefault();
			$dialog.close();
		});
		
		/* set event to locationChangeAnchors */
		$dialog.find(options.selector_locChangeA).click(function(e){
			e.preventDefault();
			var ajaxOptions = {};
			ajaxOptions.cache = options.useNoCache ? false : true;
			ajaxOptions.url = $(this).attr('href');
			ajaxOptions.success = function(data){
				$dialog.$content.html(data);
				$dialog.bindInsideEvents();
				if(options.onDialogShow){ options.onDialogShow(); }
			};
			$.ajax(ajaxOptions);
		})
		
		/* set event to locationChangeForms */
		$dialog.find(options.selector_locChangeForm).submit(function(){
			e.preventDefault();
			var $form = $(this);
			var ajaxOptions = {};
			ajaxOptions.cache = options.useNoCache ? false : true;
			ajaxOptions.url = $form.attr('action');
			ajaxOptions.type = $form.attr('method').toUpperCase();
			ajaxOptions.success = function(data){
				$.dialog.$content.html(data);
				$dialog.bindInsideEvents();
				if(options.onDialogShow){ options.onDialogShow(); }
			};
			$.ajax(ajaxOptions);
		});
		
	}; // bindInsideEvents
	
	/**
	 * bindCloseEvents()
	 */
	$dialog.bindCloseEvents = function(){
		$dialog.click(function(){
			$dialog.close(); // close if the outside of the content was clicked
		});
		$dialog.$inTableContainer.click(function(e){
			e.stopPropagation(); // but not inside
		});
	};
	
	/**
	 * open()
	 */
	$dialog.open = function(){
		$.inPageDialog.currentDialog = this;
		$.overlay.show();
		setTimeout(function(){ // keep min time
			if($.browser.msie6){
				/* IE6 is not cool at fading so just show */
				/* IE6 sometimes cant caliculate table's height 100% correctly */
				$dialog.$posTable.height($win.height());
				$dialog.show();
				$dialog.$inTableContainer.show();
				$dialog.$content.show();
				$dialog.setPosition();
				$dialog.bindAdjustEvents();
				afterLoad();
			}else{
				$dialog.show();
				$dialog.$inTableContainer.fadeIn(options.fadeSpeed, function(){
					afterLoad();
				});
			}
			function afterLoad(){
				$.overlay.loading.hide();
				whileAnimation = false;
				$dialog.$closeBtn.click(function(e){
					e.preventDefault();
					$dialog.close();
				});
				if(options.onDialogShow){ options.onDialogShow(); }
			}
		},50);
	}; // open
	
	/**
	 * close()
	 */
	$dialog.close = function(){
		whileAnimation = true; // start animation
		if($.browser.msie6){
			/* IE6 is not cool at fading so just hide */
			afterHide();
			$dialog.unbindAdjustEvents();
		}else{
			$dialog.$inTableContainer.fadeOut(options.fadeSpeed, function(){
				afterHide();
			});
		}
		function afterHide(){
			whileAnimation = false; // end animation
			$dialog.hide();
			
			/* temporary replace $.overlay.onHide */
			var func = $.overlay.onHide;
			$.overlay.onHide = function(){
				if(options.onDialogHide){ options.onDialogHide(); }
				$.inPageDialog.currentDialog = null;
				$.inPageDialog.currentDialogSet = null;
				$.overlay.onHide = func;
			};
			$.overlay.iframe.hide();
			$.overlay.color.hide();
			
		}
	}; // close
	
	/**
	 * bindAdjustEvents/unbindAdjustEvents - IE6
	 * IE6 doesnot support position:fixed. so, use absolute instead.
	 * this method will adjust the dialog's position when scroll and resize.
	 */
	$dialog.bindAdjustEvents = function(){
		if(!$.browser.msie6) return;
		$win.bind('scroll resize',adjust);
	};
	$dialog.unbindAdjustEvents = function(){
		if(!$.browser.msie6) return;
		$win.unbind('scroll resize',adjust);
	};
	function adjust(){
		if($dialog.is(':hidden')) return;
		$dialog.setPosition();
	}
	
	/**
	 * setPosition() - IE6
	 * IE6 doesnot support position:fixed. so, use absolute instead.
	 * this method will adjust the dialog's position.
	 */
	$dialog.setPosition = function(){
		if(!$.browser.msie6) return;
		// IE6 sometimes cant caliculate table's height 100% correctly
		$dialog.css({
			'top' : $win.scrollTop(),
			'left' : $win.scrollLeft()
		});
		$dialog.$posTable.height($win.height());
		return;
	};
	
	return $dialog;
	
};

/**
 * createDialog_*(options)
 * extended factories
 */
	/**
	 * createDialog_img(options)
	 */
	var createDialog_img = function(options){
		var $dialog = createDialog_base(options);
		$dialog.$img = $('<img src="'+options.url+'" alt="" />');
		$.overlay.show();
		$dialog.$img.load(function(){
			$dialog.$content.append($dialog.$img);
			$dialog.$img.click(function(){
				$.inPageDialog.close();
			});
			$body.append($dialog); // put dialog into the page
			$dialog.bindCloseEvents();
			$dialog.bindInsideEvents();
			$dialog.open();
		});
		return $dialog;
	}; // createDialog_img

	/**
	 * createDialog_ajax(options)
	 */
	var createDialog_ajax = function(options){
		var $dialog = createDialog_base(options);
		var ajaxOptions = {};
		ajaxOptions.cache = options.useNoCache ? false : true;
		ajaxOptions.url = $dialog.url;
		ajaxOptions.success = function(data){
			$dialog.$content.html(data);
			$body.append($dialog); // put dialog into the page
			$dialog.bindCloseEvents();
			$dialog.bindInsideEvents();
			$dialog.open();
		};
		$.overlay.show();
		$.ajax(ajaxOptions);
		return $dialog;
	}; // createDialog_ajax

	/**
	 * createDialog_iframe(options)
	 */
	var createDialog_iframe = function(options){
		var $dialog = createDialog_base(options);
		/* add random str to iframe to avoid cache */
		$dialog.$iframe = $('<iframe frameborder="0" src="'+$dialog.url+'" name="inPageDialog_iframeDialog'+Math.round(Math.random()*1000)+'"></iframe>');
		$dialog.$content.append($dialog.$iframe);
		$dialog.bindCloseEvents();
		$body.append($dialog); // put dialog into the page
		$dialog.open();
		return $dialog;
	}; // createDialog_iframe

	/**
	 * createDialog_anchor(options)
	 */
	var createDialog_anchor = function(options){
		var $dialog = createDialog_base(options);
		$dialog.$content.html($($dialog.url).html()); // url is anchor(#id) here
		$dialog.bindCloseEvents();
		$dialog.bindInsideEvents();
		$body.append($dialog); // put dialog into the page
		$dialog.open();
		return $dialog;
	}; // createDialog_anchor


})(jQuery); // end $ encapsulation
