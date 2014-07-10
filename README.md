# PDF Stitcher

PDF Stitcher is a tool that will stitch together PDF files. You can either give it a web page containing a list of PDF files or drag-and-drop files onto the app and it will stitch them together into a single PDF file.

It's great for compiling free textbooks available online as a list of chapters, such as [Foundations of Computer Science](http://i.stanford.edu/~ullman/focs.html) for example, or multiple PDF files printed from other sources.

This is also hosted as a service available at [http://www.pdfstitcher.com](http://www.pdfstitcher.com).

## Dependencies

PDF Stitcher is written in Ruby, uses Bundler to handle gems and leverages Ghostscript to stitch PDF files together.