# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


c1 = Contact.create(name: 'Giamia',about: 'Although Giamia came from a humble spark of lightning, he quickly grew to be a great craftsman, providing all the warming instruments needed by those close to him.',avatar: 'images/contacts/giamia.png')
c2 = Contact.create(name: 'Anostagia',about: 'Knowing there was a need for it, Anostagia drew on her experience and spearheaded the Flint & Flame storefront. In addition to coding the site, she also creates a few products available in the store.',avatar: 'images/contacts/anostagia.png')

p1 = Product.create(title: 'flint',price: 99,description: 'Flint is a hard, sedimentary cryptocrystalline form of the mineral quartz, categorized as a variety of chert.',isOnSale: true, image: 'images/products/flint.png',contact_id: c1.id)
p2 = Product.create(title: 'Kindling',price: 249,description: 'Easily combustible small sticks or twigs used for starting a fire.',isOnSale: false, image: 'images/products/kindling.png',contact_id: c2.id)
p3 = Product.create(title: 'Bow Drill',price: 999,description: 'The bow drill is an ancient tool. While it was usually used to make fire, it was also used for primitive woodworking and dentistry.',isOnSale: false, image: 'images/products/bow-drill.png',contact_id: c1.id)
p4 = Product.create(title: 'Tinder',price: 499,description: 'Tinder is easily combustible material used to ignite fires by rudimentary methods.',isOnSale: true, image: 'images/products/tinder.png',contact_id: c2.id)
p5 = Product.create(title: 'Birch Bark Shaving',price: 899,description: 'Fresh and easily combustable',isOnSale: true, image: 'images/products/birch.png',contact_id: c2.id)
p6 = Product.create(title: 'Matches',price:550,description:'One end is coated with a material that can be ignited by frictional heat generated by striking the match against a suitable surface.', isOnSale: true, image:'images/products/matches.png', contact_id: c2.id)

r1 = Review.create(reviewedAt: (DateTime.now - 3.days),text: "Started a fire in no time!",rating: 4, product_id: p3.id)
r2 = Review.create(reviewedAt: DateTime.now,text: "Not the brightest flame, but warm!",rating: 3, product_id: p6.id)
r3 = Review.create(reviewedAt: (DateTime.now - 5.days),text: "This is some amazing Flint! It lasts **forever** and works even when damp! I still remember the first day when I was only a little fire sprite and got one of these in my flame stalking for treemas. My eyes lit up the moment I tried it! Here's just a few uses for it:\n\n* Create a fire using just a knife and kindling!\n* Works even after jumping in a lake (although, that's suicide for me)\n* Small enough to fit in a pocket -- if you happen to wear pants\n\n\nYears later I'm still using the _same one_. That's the biggest advantage of this -- it doesn't run out easily like matches. As long as you have something to strike it against, **you can start a fire anywhere** you have something to burn!",rating: 5, product_id: p1.id)
