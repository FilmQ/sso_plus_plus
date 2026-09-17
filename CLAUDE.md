ALWAYS use ASD-STE100 Standard English for output and comments.

Follow the Material 3 design guide for this Flutter project. The project WILL be deployed as both a web-interface and a mobile interface.

Reuse components if possible, keep file length short, don't hesitate to create new file for new components.

Implement design as described in this Figma scheme: https://www.figma.com/design/yGZrD3LH6RRn8MVXo1LAwv/SSO-Plus-Plus?node-id=0-1&p=f&t=Kgji38gs7CX98m6b-0

Implement the use-cases in the directory `lib/use-cases` with the following link as a reference: https://docs.google.com/presentation/d/1ssIeYEtg86tsbc_oEOzbAf2tJUGJ24CcHsabxIloHgs/edit?slide=id.p1#slide=id.p1

AS OF NOW, DECOUPLE THE SERVICE LAYER FROM THE REPOSITORY LAYER AS THE TABLE SCHEMAS ARE CURRENTLY INCOMPLETE, COUPLING THEM NOW WOULD RESULT IN REDUNDANT TASKS. AS OF RIGHT NOW IN THE `lib/repository` SIMPLY HARDCODE THE DATA AS NEEDED IN ORDER FOR THE DEMO TO WORK.