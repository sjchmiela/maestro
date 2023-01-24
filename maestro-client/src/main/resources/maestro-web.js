(function ( maestro ) {
    const INVALID_TAGS = new Set(['noscript', 'script', 'br', 'img', 'svg', 'g', 'path'])

    const isInvalidTag = (node) => {
        return INVALID_TAGS.has(node.tagName.toLowerCase())
    }

    const getNodeText = (node) => {
        switch (node.tagName.toLowerCase()) {
            case 'input':
                return node.value || node.placeholder || node.ariaLabel || ''

            default:
                const childNodes = [...(node.childNodes || [])].filter(node => node.nodeType === Node.TEXT_NODE)
                return childNodes.map(node => node.textContent.replace('\n', '').replace('\t', '')).join('')
        }
    }

    const getNodeBounds = (node) => {
        const rect = node.getBoundingClientRect()

        return `[${Math.round(rect.x)},${Math.round(rect.y)}][${Math.round(rect.x+rect.width)},${Math.round(rect.y+rect.height)}]`
    }

    const isDocumentLoading = () => document.readyState !== 'complete'

    const traverse = (node) => {
      if (!node || isInvalidTag(node)) return null

      const children = [...node.children || []].map(child => traverse(child)).filter(el => !!el)
      const attributes = {
          text: getNodeText(node),
          bounds: getNodeBounds(node),
      }

      if (!!node.id || !!node.ariaLabel || !!node.name || !!node.title || !!node.htmlFor) {
        attributes['resource-id'] = node.id || node.ariaLabel || node.name || node.htmlFor
      }

      if (node.tagName.toLowerCase() === 'body') {
        attributes['is-loading'] = isDocumentLoading()
      }

      return {
        attributes,
        children,
      }
    }

    // -------------- Public API --------------
    maestro.getContentDescription = () => {
        return traverse(document.body)
    }

    // https://stackoverflow.com/a/5178132
    maestro.createXPathFromElement = (domElement) => {
        var allNodes = document.getElementsByTagName('*');
        for (var segs = []; domElement && domElement.nodeType == 1; domElement = domElement.parentNode)
        {
            if (domElement.hasAttribute('id')) {
                    var uniqueIdCount = 0;
                    for (var n=0;n < allNodes.length;n++) {
                        if (allNodes[n].hasAttribute('id') && allNodes[n].id == domElement.id) uniqueIdCount++;
                        if (uniqueIdCount > 1) break;
                    };
                    if ( uniqueIdCount == 1) {
                        segs.unshift('id("' + domElement.getAttribute('id') + '")');
                        return segs.join('/');
                    } else {
                        segs.unshift(domElement.localName.toLowerCase() + '[@id="' + domElement.getAttribute('id') + '"]');
                    }
            } else if (domElement.hasAttribute('class')) {
                segs.unshift(domElement.localName.toLowerCase() + '[@class="' + domElement.getAttribute('class') + '"]');
            } else {
                for (i = 1, sib = domElement.previousSibling; sib; sib = sib.previousSibling) {
                    if (sib.localName == domElement.localName)  i++; };
                    segs.unshift(domElement.localName.toLowerCase() + '[' + i + ']');
            };
        };
        return segs.length ? '/' + segs.join('/') : null;
    }
}( window.maestro = window.maestro || {} ));

const id = 'cursor-click-animation-canvas'
const color = '56, 96, 242'

const getOrCreateCanvas = () => {
	let canvas = document.getElementById(id)
	if (!!canvas) return canvas

	canvas = document.createElement('canvas')
  canvas.id = id
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight
  canvas.style.zIndex = 10000
  canvas.style.position = 'fixed'
  canvas.style.top = 0
  canvas.style.left = 0


  const body = document.getElementsByTagName("body")[0]
  body.appendChild(canvas);

  return document.getElementById(id)
}

document.onmouseup = ({ clientX, clientY }) => {
    const canvas = getOrCreateCanvas()
    const r = 25

    const ctx = canvas.getContext('2d')
    ctx.beginPath()
    ctx.fillStyle = `rgba(${color}, 1.0)`
    ctx.arc(clientX, clientY, r, 0, Math.PI*2)
    ctx.fill()
    ctx.closePath()

    let count = 0;
    let interval = setInterval(() => {
        ctx.clearRect(clientX-50, clientY-50, 100, 100);
        if (count < 25) {
          count++
          ctx.beginPath()
          ctx.fillStyle = `rgba(${color}, ${1 - 0.04 * count})`
          ctx.arc(clientX, clientY, r + 0.3 * count, 0, Math.PI*2)
          ctx.fill()
          ctx.closePath()
        } else {
          clearInterval(interval)
          canvas.remove()
        }
    }, 5)
}