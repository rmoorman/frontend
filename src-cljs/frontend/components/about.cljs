(ns frontend.components.about
  (:require [cljs.core.async :as async :refer [>! <! alts! chan sliding-buffer close!]]
            [clojure.string :as str]
            [frontend.components.common :as common]
            [frontend.components.shared :as shared]
            [frontend.state :as state]
            [frontend.stefon :as stefon]
            [frontend.utils :as utils :include-macros true]
            [om.core :as om :include-macros true])
  (:require-macros [frontend.utils :refer [defrender html]]))

(defn team []
  [{:name "Paul Biggar"
    :role "Founder"
    :github "pbiggar"
    :twitter "paulbiggar"
    :email "paul@circleci.com"
    :img-path (stefon/asset-path "/img/outer/about/paul.png")
    :visible true
    :bio ["Paul Biggar is cofounder and CEO of CircleCI. In past lives, he wrote phc, an open source PHP compiler, while doing his PhD on compilers and static analysis in Dublin. He has been accepted to YCombinator, given talks at Facebook and Google, been interviewed by the Wall Street Journal, and once (mostly) landed a backflip on skis!",
          "After moving to the Bay Area in 2011, Paul worked on the Firefox Javascript engine, then he co-founded CircleCI. Because it pains Paul to see so much time wasted due to inadequate developer tools, he approaches continuous integration and delivery from the perspective of developer productivity. He loves to focus on building the CircleCI product, but is currently kept so busy taking care of the business side of things that his coding fingers are getting restless."]}
    {:name "Jenneviere Villegas"
    :img-path (stefon/asset-path "/img/outer/about/jenneviere.png")
    :visible true
    :role "Operations"
    :github "jenneviere"
    :twitter "jenneviere"
    :email "jenneviere@circleci.com"
    :bio ["Jenneviere moved to the Bay Area in 2010 after spending a few months there, singing and dancing, as the lead in a rock opera. She then worked as an extra on the movie Twixt, and when she realized that Mr. Coppola wasn't going to cast her as the lead in his next film, she began drowning her sorrows in hoppy IPAs and the soothing click of knitting needles. She took the black and works the Gate at That Thing In The Desert, and has only written a single line of code, ever.",
          "Drawing from her many years' experience in her previous position as the Customer Amazement Specialist, Operations Manager, Returns Siren, and Retail Store Maven for a certain large utility kilt manufacturer, Jenneviere brings her skills as a professional pottymouth, dabbler in inappropriate and snarky humor, and cat wrangling to the team at Circle, and spends most of her time trying to keep everyone well-groomed and hairball free."]}
   {:name "David Lowe"
    :visible true
    :role "Backend Developer"
    :github "dlowe"
    :twitter "j_david_lowe"
    :email "dlowe@circleci.com"
    :img-path (stefon/asset-path "/img/outer/about/david.png")
    :bio ["David is responsible for all of the bugs. He wrote his first buggy code in BASIC with a pencil and paper, and he's been getting better at it ever since. He keeps a 1/4 acre garden and eats almost entirely home-grown veggies during the growing season. Helping to balance out the numerous times that he's lost at chess, David has won the IOCCC on 6 separate occasions. In a past life, he wrote MTA software which at one time was sending about 1% of the internet's email.",
          "Besides being invited to speak at the Frozen Perl Conference, OIT's CSET Department, and SOU's CS Department, David co-founded the SF perl user group, the southern Oregon geek group, and the Rogue hack lab hackerspace. He drank the automated testing kool-aid years ago, and after introducing and championing (and constantly fiddling with) continuous integration tools at his last N jobs, he came to Circle, and is particularly keen on building and scaling things which would be impossible to justify for any single small company where CI isn't what they do. He splits his time between introducing new bugs, telling kids to get off his lawn, and baking pies. His current running total is roughly 1500 delicious pastry concoctions."]}
   {:name "Mahmood Ali"
    :img-path (stefon/asset-path "/img/outer/about/mahmood.png")
    :visible true
    :role "Backend Developer"
    :github "notnoopci"
    :twitter "notnoop"
    :email "mahmood@circleci.com"
    :bio ["Mahmood loves car camping, which might explain why he also likes moving as much as he does. He and his family have moved 6 times in the last 6 years, though his baby boy has been completely lazy and hasn't offered to carry a single box yet. In between relocation to new abodes, Mahmood spends the nicer Boston weather exploring bike trails and learning computer languages. He's determined that his son will know Java before he can talk.",
          "During his time at MIT, Mahmood spoke at a few Java research conferences including Devoxx, and has pushed code to Java 8--and Java 7--compilers. He's been a speaker at OOPSLA/Splash, and is active in the open-source community. He enjoys being reminded of his in-production projects, like java-apns, every time he gets support tickets. He acknowledges his own fallibility, and aims to help the Circle team continue to bring reliable test automation to all developers. His Achilles Heel is his pair of permanently underachieving glasses."]}
   {:name "Gordon Syme"
    :img-path (stefon/asset-path "/img/outer/about/gordon.png")
    :visible true
    :role "Backend Developer"
    :github "gordonsyme"
    :twitter "gordon_syme"
    :email "gordon@circleci.com"
    :bio ["Gordon has been racing dinghies right through the winter off the coast of Ireland for the past 16-odd years, and as his oft-showcased cabinet of prize coffee mugs will tell you, he's damn good at it. When he's not busy bludgeoning a piano with his ham-fisted fingers, he spends his free time rolling down mountains on a bicycle… sometimes even the right way up. In his down time, he's a board game shark, though you won't catch him trying to buy Boardwalk or get out of jail free.",
          "Gordon joins the team after spending significant time at Amazon building tools to monitor the entire network (he built their DWDM monitoring from the ground up). He also built a JVM bytecode recompiler to enable running applications on a clustered VM without needing re-programming effort, and has grand plans for how he's going to make waves at Circle. We're pretty sure they include company Power Grid tournaments."]}
   {:name "Nick Gottlieb"
    :img-path (stefon/asset-path "/img/outer/about/nick.png")
    :visible true
    :role "Marketing Engineer"
    :github "worldsoup"
    :twitter "worldsoup"
    :email "nick@circleci.com"
    :bio ["Nick is an aspiring merman who spends most of his time outside of the Circle office in the ocean; surfing, diving, sailing, and swimming. He lived in Japan for 3 years as a student, consultant, actor, and vagabond and wrote his senior thesis on the cultural importance of baseball in the country. He won a hackathon by building a social haiku app for iPhone (which is still in the App Store). Eventually he came back to the US and got his first ‘real job’ at a digital consultancy where he optimized conversion rates for websites that comprise hundreds of thousands of visitors and generate millions in revenue every month.",
          "In 2012 Nick was lured to San Francisco by the prospect of hitting it big with his own startup, which crashed and burned, but he liked the place so decided to stick around. He loves the open work culture at Circle which allows him to fulfill his constant need to get-shit-done while helping developers do the same. One day he will unplug his computer and sail around the world."]}
   {:name "Emile Snyder"
    :img-path (stefon/asset-path "/img/outer/about/emile.png")
    :visible true
    :role "Backend Developer"
    :github "esnyder"
    :twitter "emilesnyder"
    :email "emile@circleci.com"}
   {:name "Tim Dixon"
    :img-path (stefon/asset-path "/img/outer/about/tim.png")
    :visible true
    :role "Developer"
    :github "startling"
    :email "tim@circleci.com"}
   {:name "Ian Duncan"
    :img-path (stefon/asset-path "/img/outer/about/ian.png")
    :visible true
    :role "Developer"
    :github "iand675"
    :twitter "iand675"
    :email "ian@circleci.com"
    :bio ["Ian joins the CircleCI team remotely from South Carolina. When he’s not busy coding away on CircleCI, he’s probably off hacking on his Haskell side projects or studying distributed systems with a quality microbrew in hand. He started learning Haskell in high school for some research projects, and has been hooked on functional programming ever since. Ian's always had more ideas for things to build than time on his hands, but managed to win runner up in a few entrepreneurship competitions in college for his work.",
          "He’s particularly fond of travel, and has done two cross-country moves in 2 years. He loves getting to know foreign cultures, and has learned to speak some Japanese and French along the way. During the summer months, he spends his time bicycling, hiking, and running, and once the weather turns cold he hones his gaming skills on Dance Dance Revolution and Super Smash Bros, sits back and binge-watches television shows (currently: Castle and Brooklyn Nine-Nine), and chows down on pumpkin pie."]}
   {:name "Kevin Bell"
    :visible true
    :role "Developer Evangelist"
    :github "bellkev"
    :twitter "iamkevinbell"
    :email "kevin@circleci.com"}
   {:name "Cayenne Geis"
    :img-path (stefon/asset-path "/img/outer/about/cayenne.png")
    :visible true
    :role "Developer"
    :github "cayennes"
    :email "cayenne@circleci.com"}
   {:name "Jonathan Irving"
    :img-path (stefon/asset-path "/img/outer/about/jonathan.png")
    :visible true
    :role "Developer"
    :github "j0ni"
    :twitter "j0ni"
    :email "jonathan@circleci.com"}
   {:name "Tim Reinke"
    :img-path (stefon/asset-path "/img/outer/about/timr.png")
    :visible true
    :role "Developer Success"
    :github "musicalchair"
    :twitter "timreinke"
    :email "tim.reinke@circleci.com"}
   {:name "Travis Vachon"
    :visible true
    :role "Developer"
    :github "travis"
    :twitter "tvachon"
    :email "travis@circleci.com"}])

(def placeholder-image [:svg.about-placeholder {:height "150px" :width "150px" :viewBox "0 0 150 150"}
                        [:path.bust {:d "M-1.673,151.75v-13.856c0,0,0.901-8.505,11.143-11.142c0,0,16.495-6.022,29.415-11.646 c6.681-2.907,8.119-4.652,14.859-7.631c0,0,0.703-3.461,0.45-5.521h5.271c0,0,1.204,0.702,0-7.43c0,0-6.425-1.705-6.725-14.655 c0,0-4.825,1.625-5.121-6.224c-0.202-5.321-4.318-9.939,1.607-13.753l-3.012-8.131c0,0-6.023-32.826,11.294-28.008 c-7.305-8.734,41.409-17.465,44.574,10.24c0,0,2.256,14.958,0,25.197c0,0,7.113-0.824,2.357,12.852c0,0-2.609,9.836-6.627,7.628 c0,0,0.656,12.447-5.668,14.559c0,0,0.449,6.625,0.449,7.075l6.025,0.903c0,0-0.906,5.424,0.152,6.022c0,0,7.142,4.894,15.657,7.081 c16.414,4.212,35.837,11.44,35.837,17.766c0,0,1.659,8.435,1.659,18.673H-1.673z",
                                     :fill "#ccc"}]])

(defn placeholder-bio [name]
  [:div.bio-coming-soon
   [:p
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi iaculis mi ante, at mattis purus varius sed. Maecenas sollicitudin volutpat nunc eget volutpat. Fusce sollicitudin adipiscing tincidunt. Duis tincidunt quis eros id egestas. Nunc ac nisi mollis, egestas enim quis, bibendum odio. Vestibulum facilisis lorem ante, ut placerat elit pellentesque non. Maecenas blandit urna non pharetra venenatis. Quisque malesuada, tellus nec porta luctus, mi lorem mattis elit, sit amet semper neque ligula sed orci. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Suspendisse eu lectus lobortis, condimentum orci faucibus, porta leo. Donec pretium sapien sit amet orci rhoncus, in suscipit erat fringilla. Donec viverra nulla dolor. Nam id libero ultricies, viverra nisi et, commodo lorem. Maecenas ac risus lobortis, pellentesque ante in, consectetur nulla."]
   [:div.coming-soon
    {:placeholder (str "Sorry, we're still working on " (first (str/split name #" ")) "'s bio.")}]])

(defn contact [app owner]
  (reify
    om/IRender
    (render [_]
      (html
       [:div#contact.contact.page
        [:div.banner
         [:div.container
          [:h1 "Contact us"]
          [:h3 "We'd love to hear from you."]]]
        [:div.container.content
         [:div.row
          [:div.span6 [:h3 "Fill the form"]
           (om/build shared/contact-form app)]
          [:div.span6.vcard
           [:h3 "Don't like forms? Contact us anyway!"]
           [:ul
            [:li [:a.email {:href "mailto:sayhi@circleci.com"}
                  [:i.fa.fa-envelope]
                  "sayhi@circleci.com"]]
            [:li [:a {:href "https://twitter.com/circleci"}
                  [:i.fa.fa-twitter]
                  "@circleci"]]
            [:li.tel [:i.fa.fa-phone " 800 585-7075 / +1 415 944-3995"]]
            [:li.adr [:i.fa.fa-globe]
             [:a {:target "_blank", :href "https://goo.gl/maps/uhkLn"}
              [:span.postal-code "94105"]]]]
           [:h3 "Press Inquiries"]
           [:p
            "Drop a line to "
            [:a {:href "mailto:press@circleci.com"} "press@circleci.com"]
            " or call Laura at +1 415 373 4089."]]]]]))))

(defn about [app owner]
  (reify
    om/IRender
    (render [_]
      (html
       [:div
        [:div.about.page
         [:div.banner
          [:div.container
           [:h1 "About us"]
           [:h3
            "CircleCI was founded in 2011 with the mission of giving every developer state of the art automated testing and continuous integration tools."]]]
         [:div.container.content
          [:h2 "Meet the CircleCI Team"]
          (map-indexed
           (fn [i member]
             [:div.member.row {:class (if (odd? i) "right" "left")}
              (if (:img-path member)
                [:img {:alt (:name member)
                       :height 150
                       :src (:img-path member)
                       :width 150
                       :class (if (odd? i) "pull-right" "pull-left")}]

                placeholder-image)
              [:div.span9
               [:h3 (:name member)]
               [:h4 (:role member)]
               [:ul.clearfix
                [:li
                 [:a.fa.fa-envelope {:href (str "mailto:" (:email member))}]
                 " "
                 [:a.fa.fa-github {:href (str "https://github.com/" (:github member))}]
                 " "
                 [:a.fa.fa-twitter {:href (str "https://twitter.com/" (:twitter member))}]]]
               (if (:bio member)
                 (for [p (:bio member)]
                   [:p p])
                 (placeholder-bio (:name member)))]])
           (team))
          [:div#jobs-cta
           [:p
            "We're looking for amazing people to join us on this journey. Want to join the team? "]
           [:a.btn.btn-large.btn-primary
            {:href "/jobs"}
            "CircleCI is hiring!"]]]]
        (om/build contact app)]))))
