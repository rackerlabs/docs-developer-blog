# Title: Zoomable Image tag wrapper for Jekyll
# Authors: Max Lincoln
# Description: Just wraps a normal image tag, adding a link to view the full image.
#
# Syntax {% zoomable_img [class name(s)] [http[s]:/]/path/to/image [width [height]] [title text | "title text" ["alt text"]] %}
#
# Examples:
# {% zoomable_img ninja.png Ninja Attack! %}
# {% zoomable_img left half https://site.com/images/ninja.png Ninja Attack! %}
# {% zoomable_img left half https://site.com/images/ninja.png 150 150 "Ninja Attack!" "Ninja in attack posture" %}
#
# Output:
# <a href="/images/ninja.png""><img src="/images/ninja.png"></a>
# <a href="https://site.com/images/ninja.png"><img class="left half" src="https://site.com/images/ninja.png" title="Ninja Attack!" alt="Ninja Attack!"></a>
# <a href="https://site.com/images/ninja.png"><img class="left half" src="https://site.com/images/ninja.png" width="150" height="150" title="Ninja Attack!" alt="Ninja in attack posture"></a>
#

module Jekyll

  class ZoomableImageTag < Jekyll::ImageTag
    def render(context)
      inner = super
      "<a href=\"#{@img['src']}\">#{inner}</a>"
    end
  end
end

Liquid::Template.register_tag('zoomable_img', Jekyll::ZoomableImageTag)
