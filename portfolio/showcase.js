'use strict';
const groups = {
  welcome: [
    {file:'splash',label:'Splash',title:'One clear identity.',chapter:'THE FIRST IMPRESSION',description:'The MyShop bag mark and a quiet cream canvas make the first moment feel familiar.',features:['Custom shopping bag identity','Branded native iPhone launch','A matching in-app splash']},
    {file:'onboarding-discover',label:'Discover',title:'Find your next favourite.',chapter:'WELCOME / DISCOVER',description:'A sculptural tote, headphones and a sage cup introduce the collection with a little personality.',features:['Artwork created for MyShop','Swipe, Continue or Skip','Larger text and reduced motion']},
    {file:'onboarding-basket',label:'Your basket',title:'Your basket, your way.',chapter:'WELCOME / MAKE IT YOURS',description:'Bring your favourite finds together, then choose your address and how to check out.',features:['A connected welcome story','Back and forward navigation','Progress through three chapters']},
    {file:'onboarding-orders',label:'Your orders',title:'Keep your orders close.',chapter:'WELCOME / STAY ORGANISED',description:'The final welcome page introduces purchases and delivery details, beautifully organised in one place.',features:['A clear Get started action','Completion remembered on this installation','Revisit purchases in order history']}
  ],
  discover: [
    {file:'home',label:'Home',title:'Something you’ll love.',chapter:'DISCOVER / HOME',description:'The storefront brings search, categories, delivery information and saved finds into one place.',features:['Search and category discovery','Saved items and recently viewed products','A sample collection across four categories']},
    {file:'categories',label:'Categories',title:'Explore the collection.',chapter:'DISCOVER / CATEGORIES',description:'Browse a category or refine the collection with price, availability and sorting controls.',features:['Categories and product search','Price and stock filters','Saved items and stock indicators']},
    {file:'product',label:'Product',title:'Look a little closer.',chapter:'DISCOVER / PRODUCT DETAILS',description:'A generous product image, clear price and availability help each find feel tangible.',features:['Product imagery and description','Stock information and saved favourites','Add an available item to your basket']}
  ],
  checkout: [
    {file:'cart',label:'Basket',title:'All your favourites, together.',chapter:'CHECKOUT / YOUR BASKET',description:'A personal basket with quantity controls, a clear subtotal and a direct path to checkout.',features:['Account-scoped saved basket','Quantity limits and easy removal','EGP pricing with stock checked at checkout']},
    {file:'checkout',label:'Checkout',title:'Choose your next step.',chapter:'CHECKOUT / DELIVERY & PAYMENT',description:'Choose an address and a shipping method, then review a Cash on Delivery demo or hosted Sandbox payment.',features:['Saved addresses and default delivery details','Standard or Express shipping','Sandbox card payments and demo cash orders']}
  ],
  orders: [
    {file:'order-details',label:'Order details',title:'Every detail stays close.',chapter:'ORDERS / DELIVERY DETAILS',description:'Return to a placed order to see the estimated delivery, status timeline and saved address.',features:['Order history tied to the signed-in account','A clear order status and delivery estimate','Illustrative timeline; no live courier tracking']},
    {file:'order-summary',label:'Order summary',title:'The whole order, together.',chapter:'ORDERS / PURCHASE SUMMARY',description:'Delivery, payment, purchased items and the final total remain together after checkout.',features:['Purchased items and quantities','Payment method and shipping cost','Historical order currencies preserved']}
  ]
};
let group = 'welcome';
let index = 0;
const byId = id => document.getElementById(id);
const tabs = Array.from(document.querySelectorAll('[role="tab"]'));
const dialog = byId('screen-dialog');
function render() {
  const screens = groups[group];
  const screen = screens[index];
  const image = byId('screen-image');
  image.src = `assets/screens/${screen.file}.png`;
  image.alt = `MyShop ${screen.label}: ${screen.description}`;
  byId('screen-title').textContent = screen.title;
  byId('screen-description').textContent = screen.description;
  byId('screen-chapter').textContent = screen.chapter;
  byId('screen-count').textContent = `${String(index+1).padStart(2,'0')} / ${String(screens.length).padStart(2,'0')}`;
  byId('screen-panel').setAttribute('aria-labelledby',`tab-${group}`);
  byId('screen-features').replaceChildren(...screen.features.map(text => {const li = document.createElement('li');li.textContent=text;return li;}));
  tabs.forEach(tab => {const active = tab.dataset.group===group;tab.setAttribute('aria-selected',String(active));tab.tabIndex=active?0:-1;});
  const thumbnails = screens.map((item,i) => {
    const button = document.createElement('button');button.className='thumbnail';button.type='button';button.setAttribute('aria-pressed',String(i===index));button.setAttribute('aria-label',`Show ${item.label}`);
    const img = document.createElement('img');img.src=`assets/screens/${item.file}.png`;img.alt='';img.width=900;img.height=1957;
    const label = document.createElement('span');label.textContent=item.label;button.append(img,label);button.addEventListener('click',()=>{index=i;render();byId('thumbnails').children[i].focus({preventScroll:true});});return button;
  });
  byId('thumbnails').replaceChildren(...thumbnails);
  if(dialog.open) syncDialog();
}
function step(amount){index=(index+amount+groups[group].length)%groups[group].length;render();}
function selectGroup(next){group=next;index=0;render();}
function syncDialog(){const screen=groups[group][index];byId('dialog-title').textContent=`MyShop / ${screen.label}`;byId('dialog-image').src=`assets/screens/${screen.file}.png`;byId('dialog-image').alt=`MyShop ${screen.label}`;}
tabs.forEach((tab,i)=>{
  tab.addEventListener('click',()=>selectGroup(tab.dataset.group));
  tab.addEventListener('keydown',event=>{let next;if(event.key==='ArrowRight')next=(i+1)%tabs.length;if(event.key==='ArrowLeft')next=(i-1+tabs.length)%tabs.length;if(event.key==='Home')next=0;if(event.key==='End')next=tabs.length-1;if(next!==undefined){event.preventDefault();selectGroup(tabs[next].dataset.group);tabs[next].focus();}});
});
byId('previous-screen').addEventListener('click',()=>step(-1));
byId('next-screen').addEventListener('click',()=>step(1));
function openScreen(){syncDialog();dialog.showModal();}
byId('open-screen').addEventListener('click',openScreen);
byId('screen-zoom').addEventListener('click',openScreen);
byId('close-dialog').addEventListener('click',()=>dialog.close());
byId('dialog-previous').addEventListener('click',()=>step(-1));
byId('dialog-next').addEventListener('click',()=>step(1));
dialog.addEventListener('click',event=>{if(event.target===dialog){const r=dialog.getBoundingClientRect();if(event.clientX<r.left||event.clientX>r.right||event.clientY<r.top||event.clientY>r.bottom)dialog.close();}});
dialog.addEventListener('keydown',event=>{if(event.key==='ArrowLeft'){event.preventDefault();step(-1);}if(event.key==='ArrowRight'){event.preventDefault();step(1);}});
render();
