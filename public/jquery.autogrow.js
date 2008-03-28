/* 
 * Auto Expanding Text Area (1.02)
 * by Chrys Bader (www.chrysbader.com)
 * chrysb@gmail.com
 *
 * Special thanks to:
 * Jake Chapa - jake@hybridstudio.com
 * John Resig - jeresig@gmail.com
 *
 * Copyright (c) 2008 Chrys Bader (www.chrysbader.com)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses. 
 *
 *
 * NOTE: This script requires jQuery to work.  Download jQuery at www.jquery.com
 *
 */
 
(function($) {
		  
	var self = null;
 
	$.fn.autogrow = function(o)
	{	
		return this.each(function() {
			new $.autogrow(this, o);
		});
	};
	

    /**
     * The autogrow object.
     *
     * @constructor
     * @name $.autogrow
     * @param Object e The textarea to create the autogrow for.
     * @param Hash o A set of key/value pairs to set as configuration properties.
     * @cat Plugins/autogrow
     */
	
	$.autogrow = function (e, o)
	{
		this.dummy			= null;
		this.interval		= null;
		this.line_height	= parseInt($(e).css('line-height'));
		this.min_height		= parseInt($(e).css('min-height'));
		this.options		= o;
		this.textarea		= $(e);
		
		// Only one textarea activated at a time, the one being used
		this.init();
	};
	
	$.autogrow.fn = $.autogrow.prototype = {
        autogrow: '1.1'
    };
	
 	$.autogrow.fn.extend = $.autogrow.extend = $.extend;
	
	$.autogrow.fn.extend({
						 
		init: function() {
			
			self = this;
			
			this.textarea.css({overflow: 'hidden', display: 'block'});
			this.textarea.bind('focus', function() { self.startExpand() } ).bind('blur', function() { self.stopExpand });	
		},
						 
		startExpand: function() {
			
	
			this.interval = window.setInterval(function() {self.checkExpand()}, 500);
		},
		
		stopExpand: function() {
			clearInterval(this.interval);	
		},
		
		checkExpand: function() {
			
			if (this.dummy == null)
			{
				this.dummy = $('<div></div>');
				this.dummy.css({
												'font-size': 	this.textarea.css('font-size'),
												'font-family': 	this.textarea.css('font-family'),
												'width': 		this.textarea.css('width'),
												'padding': 		this.textarea.css('padding'),
												'line-height':  this.textarea.css('line-height'),
												'overflow-x':   'hidden',
												'display':		'none',
												'position':     'absolute',
												'top':			0,
												'left':			'-9999px'
												}).appendTo('body');
			}
			
			
			var html = this.textarea.val().replace(/\n/g, '<br>new');
			
			if (this.dummy.html() != html)
			{
				this.dummy.html(html);	
				
				if (this.textarea.height() != this.dummy.height() + this.line_height)
				{
					this.textarea.animate({height: (this.dummy.height() + this.line_height) + 'px'}, 100);	
				}
			}
		}
						 
	 });
})(jQuery);